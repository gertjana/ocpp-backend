defmodule Ocpp.Messages do
  alias Ocpp.Messages.V16, as: V16
  alias Ocpp.Messages.V20, as: V20
  @moduledoc """
    This module forward all OCPP messages to the respective versions
  """

  def handle_message(message, state) do
    case state.version do
      :ocpp20 -> V20.handle_message(message, state)
      :ocpp16 -> V16.handle_message(message, state)
      _ -> {:error, "Unknown version #{state.version}"}
    end
  end

  # Generic implementations called from the version specific modules

  def handle_default(id, state) do
    {state, JSX.encode([3, id, []])}
  end

  def handle_notimplemented(id, state) do
    {state,  JSX.encode([4, id, [status: "Rejected", data: "Not Implemented"]])}
  end

  def handle_authorize(id, id_tag, state) do
    notification_status = TokenAuthorisation.authorize(id_tag)
    {state, JSX.encode([3, id, [idTagInfo: [status: notification_status, idToken: id_tag]]])}
  end

  def handle_boot_notification(id, state) do
    {state, JSX.encode([3, id, [status: "Accepted", currentTime: Utils.datetime_as_string, interval: 300]])}
  end

  def handle_datatransfer(id, _vendor_id, _message_id, state) do
    {state, JSX.encode([4, id, [status: "Rejected", data: "Not Implemented"]])}
  end

  def handle_heartbeat(id, state) do
    {state, JSX.encode([3, id, [currentTime: Utils.datetime_as_string]])}
  end

  def handle_status_notification(id, status, connector_id, state) do
    Chargepoints.update_status(state.serial, status, connector_id)
    {state, JSX.encode([3, id, []])}
  end

  def handle_start_transaction(id, [connector_id: connector_id, id_tag: id_tag, meter_start: meter_start, timestamp: timestamp], state) do
    case state do
      %{:currentTransaction => _} ->
        {state, JSX.encode([4, id, "Transaction Already started", "A session is still undergoing on this chargepoint"])}
      _ ->
        {:ok, start_time} = Timex.parse(timestamp, "{ISO:Extended}")

        {:ok, transaction_id} = Chargesessions.start(connector_id, state.serial, id_tag, start_time)

        state = Map.put(state, :currentTransaction, %{transaction_id: transaction_id, start: meter_start, timestamp: timestamp, idTag: id_tag})

        {state, JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: id_tag], transactionId: transaction_id]])}
    end
  end

  def handle_stop_transaction(id, [id_tag: id_tag, transaction_id: transaction_id, meter_stop: meter_stop, timestamp: timestamp], state) do
    case state do
      %{:currentTransaction => current_transaction} ->
        current_transaction_id = Map.get(current_transaction, :transaction_id)
        case Map.get(current_transaction, :idTag) do
          tag when tag == id_tag and current_transaction_id == transaction_id ->
            volume = meter_stop - Map.get(current_transaction, :start)
            {:ok, stop_time} = Timex.parse(timestamp, "{ISO:Extended}")

            Chargesessions.stop(Map.get(current_transaction, :transaction_id), volume, stop_time)

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
