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

  def handle_call({[2, id, "BootNotification", _], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3,id, [status: "Pending", currentTime: Utils.datetime_as_string, interval: 300]])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StatusNotification", %{"status" => status}], state}, _sender, current_state) do
    GenServer.call(Chargepoints, {:status, status, state.serial})
    {:ok, reply} = JSX.encode([3,id, []])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "CancelReservation", _], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3,id, [status: "Accepted"]])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "Heartbeat", _], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3, id, [currentTime: Utils.datetime_as_string]])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "Authorize",%{"idTag" => idToken}], state}, _sender, current_state) do
    notificationStatus = GenServer.call(TokenAuthorisation, {:rfid, idToken})
    {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: notificationStatus, idToken: idToken]]])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StartTransaction", %{"connectorId" => _, "idTag" => idTag, "meterStart" => meterStart, "timestamp" => timestamp}], state}, _sender, current_state) do
    case state do
      %{:currentTransaction => _} ->
        {:ok, reply} = JSX.encode([4, id, "Transaction Already started", "A session is still undergoing on this chargepoint"])  
        {:reply, {{:text, reply}, state}, current_state}
      _ -> 
        {state, transactionId} =  next_transaction_id(state)
        state = Map.put(state, :currentTransaction, %{id: transactionId, start: meterStart, timestamp: timestamp, idTag: idTag})

        GenServer.call(Chargesessions, {:start, transactionId, state.serial, idTag, timestamp})

        {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idTag], transactionId: transactionId]])
        {:reply, {{:text, reply}, state}, current_state}
    end 
  end

  def handle_call({[2, id, "StopTransaction", %{"idTag" => idTag, "meterStop" => meterStop, "timestamp" => timestamp}], state}, _sender, current_state) do
    case state do
      %{:currentTransaction => currentTransaction} ->
        case Map.get(currentTransaction, :idTag) do
          tag when tag == idTag ->
            volume = meterStop - Map.get(currentTransaction, :start)
            transactionId = Map.get(currentTransaction, :id)
            GenServer.call(Chargesessions, {:stop, transactionId, volume, timestamp})

            state = Map.delete(state, :currentTransaction)
            {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idTag]]])
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
