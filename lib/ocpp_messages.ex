defmodule OcppMessages do
  @moduledoc """
    This module handles all OCPP 1.6 messages
  """
  use GenServer
  import Logger

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
    info "Starting #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  def handle_call({[2, id, "Authorize", %{"idTag" => id_tag}], state}, _sender, current_state) do
    {:ok, reply} = handle_authorize(id, id_tag)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "BootNotification", _], state}, _sender, current_state) do
    {:ok, reply} = handle_boot_notification(id)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "DataTransfer", %{"vendorId" => _vendorId}], state}, _sender, current_state) do
    {:ok, reply} = handle_datatransfer(id)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "DiagnosticsStatusNotification", %{"status" => _diagStatus}], state}, _sender, current_state) do
    {:ok, reply} = handle_default(id)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "FirmwareStatusNotification", %{"status" => _firmwareStatus}], state}, _sender, current_state) do
    {:ok, reply} = handle_default(id)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "Heartbeat", _], state}, _sender, current_state) do
    {:ok, reply} = handle_heartbeat(id)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "MeterValues", %{"connectorId" => _, "transactionId" => _, "meterValue" => _meterValue}], state}, _sender, current_state) do
    {:ok, reply} = handle_default(id)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StatusNotification", %{"status" => status}], state}, _sender, current_state) do
    {:ok, reply} = handle_status_notification(id, status, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StartTransaction", %{"connectorId" => _, "transactionId" => transaction_id, "idTag" => id_tag, "meterStart" => meter_start, "timestamp" => timestamp}], state}, _sender, current_state) do
    {:ok, reply} = handle_start_transaction(id, transaction_id, id_tag, meter_start, timestamp, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StopTransaction", %{"idTag" => id_tag, "transactionId" => transaction_id, "meterStop" => meter_stop, "timestamp" => timestamp}], state}, _sender, current_state) do
    {:ok, reply} = handle_stop_transaction(id, id_tag, transaction_id, meter_stop, timestamp, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  #fallback handler, valid json, but we do not yet understand it
  def handle_call({_, state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([4, "", "Not Implemented", "This backend does not understand this message (yet)"])
    {:reply, {{:text, reply}, state}, current_state}
  end

  defp handle_default(id) do
    JSX.encode([3, id, []])
  end

  defp handle_authorize(id, id_tag) do
    notification_status = GenServer.call(TokenAuthorisation, {:token, id_tag})
    JSX.encode([3, id, [idTagInfo: [status: notification_status, idToken: id_tag]]])
  end

  defp handle_boot_notification(id) do
    JSX.encode([3, id, [status: "Pending", currentTime: Utils.datetime_as_string, interval: 300]])
  end

  defp handle_datatransfer(id) do
    JSX.encode([3, id, [status: "Rejected", data: "Not Implemented"]])
  end

  defp handle_heartbeat(id) do
    JSX.encode([3, id, [currentTime: Utils.datetime_as_string]])
  end

  defp handle_status_notification(id, status, state) do
    GenServer.call(Chargepoints, {:status, status, state.serial})
    JSX.encode([3, id, []])
  end

  defp handle_start_transaction(id, transaction_id, id_tag, meter_start, timestamp, state) do
    case state do
      %{:currentTransaction => _} ->
        JSX.encode([4, id, "Transaction Already started", "A session is still undergoing on this chargepoint"])
      _ ->
        state = Map.put(state, :currentTransaction, %{id: transaction_id, start: meter_start, timestamp: timestamp, idTag: id_tag})

        {:ok, start_time} = Timex.parse(timestamp, "{ISO:Extended}")

        GenServer.call(Chargesessions, {:start, transaction_id, state.serial, id_tag, start_time})

        JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: id_tag], transactionId: transaction_id]])
    end
  end

  defp handle_stop_transaction(id, id_tag, transaction_id, meter_stop, timestamp, state) do
    case state do
      %{:currentTransaction => current_transaction} ->
        case Map.get(current_transaction, :idTag) do
          tag when tag == id_tag ->
            volume = meter_stop - Map.get(current_transaction, :start)
            {:ok, stop_time} = Timex.parse(timestamp, "{ISO:Extended}")

            GenServer.call(Chargesessions, {:stop, transaction_id, volume, stop_time})

            state = Map.delete(state, :currentTransaction)
            JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: id_tag]]])
          _ ->
            JSX.encode([4, id, "Transaction not stopped", "you can only stop a transaction with the same idtag"])
        end
      _ ->
        JSX.encode([4, id, "Transaction not started", "you can't stop a transaction that hasn't been started"])
    end
  end
end
