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

  def handle_call({[2, id, "Authorize", %{"idTag" => id_token}], state}, _sender, current_state) do
    notification_status = GenServer.call(TokenAuthorisation, {:token, id_token})
    {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: notification_status, idToken: id_token]]])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "BootNotification", _], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode(
      [3, id, [status: "Pending", currentTime: Utils.datetime_as_string, interval: 300]])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "DataTransfer", %{"vendorId" => _vendorId}], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3, id, [status: "Rejected", data: "Not Implemented"]])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "DiagnosticsStatusNotification", %{"status" => _diagStatus}], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3, id, []])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "FirmwareStatusNotification", %{"status" => _firmwareStatus}], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3, id, []])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "Heartbeat", _], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3, id, [currentTime: Utils.datetime_as_string]])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "MeterValues", %{"connectorId" => _, "transactionId" => _, "meterValue" => _}], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3, id, []])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StatusNotification", %{"status" => status}], state}, _sender, current_state) do
    GenServer.call(Chargepoints, {:status, status, state.serial})
    {:ok, reply} = JSX.encode([3, id, []])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StartTransaction", %{"connectorId" => _, "idTag" => id_tag, "meterStart" => meter_start, "timestamp" => timestamp}], state}, _sender, current_state) do
    case state do
      %{:currentTransaction => _} ->
        {:ok, reply} = JSX.encode([4, id, "Transaction Already started", "A session is still undergoing on this chargepoint"])
        {:reply, {{:text, reply}, state}, current_state}
      _ ->
        {state, transaction_id} =  next_transaction_id(state)
        state = Map.put(state, :currentTransaction, %{id: transaction_id, start: meter_start, timestamp: timestamp, idTag: id_tag})

        {:ok, start_time} = Timex.parse(timestamp, "{ISO:Extended}")

        GenServer.call(Chargesessions, {:start, transaction_id, state.serial, id_tag, start_time})

        {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: id_tag], transactionId: transaction_id]])
        {:reply, {{:text, reply}, state}, current_state}
    end
  end

  def handle_call({[2, id, "StopTransaction", %{"idTag" => id_tag, "meterStop" => meter_stop, "timestamp" => timestamp}], state}, _sender, current_state) do
    case state do
      %{:currentTransaction => current_transaction} ->
        case Map.get(current_transaction, :idTag) do
          tag when tag == id_tag ->
            volume = meter_stop - Map.get(current_transaction, :start)
            transaction_id = Map.get(current_transaction, :id)
            {:ok, stop_time} = Timex.parse(timestamp, "{ISO:Extended}")

            GenServer.call(Chargesessions, {:stop, transaction_id, volume, stop_time})

            state = Map.delete(state, :currentTransaction)
            {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: id_tag]]])
            {:reply, {{:text, reply}, state}, current_state}
          _ ->
            {:ok, reply} = JSX.encode([4, id, "Transaction not stopped", "you can only stop a transaction with the same idtag"])
            {:reply, {{:text, reply}, state}, current_state}
        end
      _ ->
        {:ok, reply} = JSX.encode([4, id, "Transaction not started", "you can't stop a transaction that hasn't been started"])
        {:reply, {{:text, reply}, state}, current_state}
    end
  end

  #fallback handler, valid json, but we do not yet understand it
  def handle_call({_, state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([4, "", "Not Implemented", "This backend does not understand this message (yet)"])
    {:reply, {{:text, reply}, state}, current_state}
  end

  defp next_transaction_id(state) do
    state = %{state | :id => state.id + 1}
    {state, state.serial <> "_" <> Integer.to_string(state.id)}
  end
end
