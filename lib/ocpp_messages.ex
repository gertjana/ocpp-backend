defmodule Ocpp.Messages do
  @moduledoc """
    This module handles all OCPP 1.6 messages
  """
  use GenServer
  import Logger
  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  # message handlers, matches on all chargepoint -> central system messages

  def handle_call({[2, id, "Authorize", %{"idTag" => id_tag}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_authorize(id, id_tag, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "BootNotification", _], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_boot_notification(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "DataTransfer", %{"vendorId" => _vendorId}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_datatransfer(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "DiagnosticsStatusNotification", %{"status" => _diagStatus}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_default(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "FirmwareStatusNotification", %{"status" => _firmwareStatus}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_default(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "Heartbeat", _], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_heartbeat(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "MeterValues", %{"connectorId" => _, "transactionId" => _, "meterValue" => _meterValue}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_default(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StatusNotification", %{"status" => status, "connectorId" => connector_id, "errorCode" => _error_code}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_status_notification(id, status, connector_id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StartTransaction", %{"connectorId" => connector_id, "transactionId" => transaction_id, "idTag" => id_tag, "meterStart" => meter_start, "timestamp" => timestamp}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_start_transaction(id,
      [connector_id: connector_id, transaction_id: transaction_id, id_tag: id_tag, meter_start: meter_start, timestamp: timestamp], state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StopTransaction", %{"idTag" => id_tag, "transactionId" => transaction_id, "meterStop" => meter_stop, "timestamp" => timestamp}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_stop_transaction(id, [id_tag: id_tag, transaction_id: transaction_id, meter_stop: meter_stop, timestamp: timestamp], state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({_, state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([4, "", "Not Implemented", "This backend does not understand this message (yet)"])
    {:reply, {{:text, reply}, state}, current_state}
  end

  # Implementations

  defp handle_default(id, state) do
    {state, JSX.encode([3, id, []])}
  end

  defp handle_authorize(id, id_tag, state) do
    notification_status = GenServer.call(TokenAuthorisation, {:token, id_tag})
    {state, JSX.encode([3, id, [idTagInfo: [status: notification_status, idToken: id_tag]]])}
  end

  defp handle_boot_notification(id, state) do
    {state, JSX.encode([3, id, [status: "Accepted", currentTime: Utils.datetime_as_string, interval: 300]])}
  end

  defp handle_datatransfer(id, state) do
    {state, JSX.encode([3, id, [status: "Rejected", data: "Not Implemented"]])}
  end

  defp handle_heartbeat(id, state) do
    {state, JSX.encode([3, id, [currentTime: Utils.datetime_as_string]])}
  end

  defp handle_status_notification(id, status, connector_id, state) do
    GenServer.call(Chargepoints, {:status, status, state.serial, connector_id})
    {state, JSX.encode([3, id, []])}
  end

  defp handle_start_transaction(id, [connector_id: connector_id, transaction_id: transaction_id, id_tag: id_tag, meter_start: meter_start, timestamp: timestamp], state) do
    case state do
      %{:currentTransaction => _} ->
        {state, JSX.encode([4, id, "Transaction Already started", "A session is still undergoing on this chargepoint"])}
      _ ->
        state = Map.put(state, :currentTransaction, %{id: transaction_id, start: meter_start, timestamp: timestamp, idTag: id_tag})

        {:ok, start_time} = Timex.parse(timestamp, "{ISO:Extended}")

        GenServer.call(Chargesessions, {:start, connector_id, transaction_id, state.serial, id_tag, start_time})

        {state, JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: id_tag], transactionId: transaction_id]])}
    end
  end

  defp handle_stop_transaction(id, [id_tag: id_tag, transaction_id: transaction_id, meter_stop: meter_stop, timestamp: timestamp], state) do
    case state do
      %{:currentTransaction => current_transaction} ->
        case Map.get(current_transaction, :idTag) do
          tag when tag == id_tag ->
            volume = meter_stop - Map.get(current_transaction, :start)
            {:ok, stop_time} = Timex.parse(timestamp, "{ISO:Extended}")

            GenServer.call(Chargesessions, {:stop, transaction_id, volume, stop_time})

            state = Map.delete(state, :currentTransaction)
            {state, JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: id_tag]]])}
          _ ->
            {state, JSX.encode([4, id, "Transaction not stopped", "you can only stop a transaction with the same idtag"])}
        end
      _ ->
        {state, JSX.encode([4, id, "Transaction not started", "you can't stop a transaction that hasn't been started"])}
    end
  end
end
