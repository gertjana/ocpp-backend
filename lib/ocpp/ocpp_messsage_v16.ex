
defmodule Ocpp.Messages.V16 do
  alias Ocpp.Messages, as: Messages
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
    {state, {:ok, reply}} = Messages.handle_authorize(id, id_tag, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "BootNotification", _], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_boot_notification(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "DataTransfer", %{"vendorId" => vendor_id, "messageId" => message_id}], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_datatransfer(id, vendor_id, message_id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "DiagnosticsStatusNotification", %{"status" => _diagStatus}], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_default(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "FirmwareStatusNotification", %{"status" => _firmwareStatus}], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_default(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "Heartbeat", _], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_heartbeat(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "MeterValues", %{"connectorId" => _, "transactionId" => _, "meterValue" => _meterValue}], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_default(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StatusNotification", %{"status" => status, "connectorId" => connector_id, "errorCode" => _error_code}], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_status_notification(id, status, connector_id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id,  "StartTransaction", %{"connectorId" => connector_id, "idTag" => id_tag, "meterStart" => meter_start, "timestamp" => timestamp}], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_start_transaction(id,
      [connector_id: connector_id, id_tag: id_tag, meter_start: meter_start, timestamp: timestamp], state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StopTransaction", %{"idTag" => id_tag, "transactionId" => trans_id, "meterStop" => meter_stop, "timestamp" => ts}], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_stop_transaction(id, [id_tag: id_tag, transaction_id: trans_id, meter_stop: meter_stop, timestamp: ts], state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  # responses from chargepoint

  def handle_call({[3, _id, %{"status" => status}], state}, _sender, current_state) do
    info "status is #{status}"
    {:reply, {:ok, state}, current_state}
  end
end
