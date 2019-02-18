
defmodule Ocpp.Messages.V16 do
  @moduledoc """
    This module handles all OCPP 1.6 messages
  """
  use GenServer
  import Logger

    def init(args) do
    {:ok, args}
  end

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  # Client calls

    def handle_message(message, state) do
    case GenServer.call(Ocpp.Messages.V16, {message, state}) do
      {{:ok, _}, new_state} -> {:ok, new_state}
      {resp, new_state} -> {:reply, resp, new_state}
    end
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

  def handle_call({[2, id, "DataTransfer", %{"vendorId" => vendor_id, "messageId" => message_id}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_datatransfer(id, vendor_id, message_id, state)
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

  def handle_call({[2, id,  "StartTransaction", %{"connectorId" => connector_id, "idTag" => id_tag, "meterStart" => meter_start, "timestamp" => timestamp}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_start_transaction(id,
      [connector_id: connector_id, id_tag: id_tag, meter_start: meter_start, timestamp: timestamp], state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StopTransaction", %{"idTag" => id_tag, "transactionId" => transaction_id, "meterStop" => meter_stop, "timestamp" => timestamp}], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_stop_transaction(id, [id_tag: id_tag, transaction_id: transaction_id, meter_stop: meter_stop, timestamp: timestamp], state)
    {:reply, {{:text, reply}, state}, current_state}
  end
  
  # responses from chargepoint

  def handle_call({[3, _id, %{"status" => status}], state}, _sender, current_state) do
    info "status is #{status}"
    {:reply, {:ok, state}, current_state}
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

  defp handle_datatransfer(id, _vendor_id, _message_id, state) do
    {state, JSX.encode([4, id, [status: "Rejected", data: "Not Implemented"]])}
  end

  defp handle_heartbeat(id, state) do
    {state, JSX.encode([3, id, [currentTime: Utils.datetime_as_string]])}
  end

  defp handle_status_notification(id, status, connector_id, state) do
    GenServer.call(Chargepoints, {:status, status, state.serial, connector_id})
    {state, JSX.encode([3, id, []])}
  end

  defp handle_start_transaction(id, [connector_id: connector_id, id_tag: id_tag, meter_start: meter_start, timestamp: timestamp], state) do
    case state do
      %{:currentTransaction => _} ->
        {state, JSX.encode([4, id, "Transaction Already started", "A session is still undergoing on this chargepoint"])}
      _ ->
        {:ok, start_time} = Timex.parse(timestamp, "{ISO:Extended}")

        {:ok, transaction_id} = GenServer.call(Chargesessions, {:start, connector_id, state.serial, id_tag, start_time})

        state = Map.put(state, :currentTransaction, %{transaction_id: transaction_id, start: meter_start, timestamp: timestamp, idTag: id_tag})

        {state, JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: id_tag], transactionId: transaction_id]])}
    end
  end

  defp handle_stop_transaction(id, [id_tag: id_tag, transaction_id: transaction_id, meter_stop: meter_stop, timestamp: timestamp], state) do
    case state do
      %{:currentTransaction => current_transaction} ->
        current_transaction_id = Map.get(current_transaction, :transaction_id)
        case Map.get(current_transaction, :idTag) do
          tag when tag == id_tag and current_transaction_id == transaction_id ->
            volume = meter_stop - Map.get(current_transaction, :start)
            {:ok, stop_time} = Timex.parse(timestamp, "{ISO:Extended}")

            GenServer.call(Chargesessions, {:stop, Map.get(current_transaction, :transaction_id), volume, stop_time})

            state = Map.delete(state, :currentTransaction)
            {state, JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: id_tag]]])}
          _ ->
            {state, JSX.encode([4, id, "Transaction not stopped", "you can only stop a transaction with the same idtag and the same transactionId"])}
        end
      _ ->
        {state, JSX.encode([4, id, "Transaction not started", "you can't stop a transaction that hasn't been started"])}
    end
  end
end

