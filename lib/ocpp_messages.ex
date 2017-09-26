defmodule OcppMessages do
  use GenServer
  import Logger

  def start_link(_) do
    info "Starting OcppMessages module"
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end 

  def handle_call({[2, id, "BootNotification", _], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3,id, [status: "Pending", currentTime: Utils.datetime_as_string, heartbeatInterval: 300]])
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "StatusNotification", _], state}, _sender, current_state) do
    {:ok, reply} = JSX.encode([3,id, []])
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

  def handle_call({[2, id, "StartTransaction", %{"connectorId" => _, "idTag" => idToken, "meterStart" => meterStart, "timestamp" => timestamp}], state}, _sender, current_state) do
    case state do
      %{:currentTransaction => _} ->
        {:ok, reply} = JSX.encode([4, id, "Transaction Already started", "A session is still undergoing on this chargepoint"])  
        {:reply, {{:text, reply}, state}, current_state}
      _ -> 
        {state, transactionId} =  next_transaction_id(state)
        state = Map.put(state, :currentTransaction, %{id: transactionId, start: meterStart, timestamp: timestamp, idTag: idToken})
        
        {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idToken], transactionId: transactionId]])
        {:reply, {{:text, reply}, state}, current_state}
    end 
  end

  def handle_call({[2, id, "StopTransaction", %{"idTag" => idToken, "meterStop" => meterStop, "timestamp" => timestamp}], state}, _sender, current_state) do
    case state do
      %{:currentTransaction => _} ->
        storeTransaction(state, meterStop, timestamp)
        state = Map.delete(state, :currentTransaction)
        {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idToken]]])
        {:reply, {{:text, reply}, state}, current_state}
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

  defp storeTransaction(state, meterStop, timestampStop) do
    meterStart = state.currentTransaction.start
    {:ok, start_datetime} = Timex.parse(state.currentTransaction.timestamp, "{ISO:Extended}")
    {:ok, stop_datetime} = Timex.parse(timestampStop, "{ISO:Extended}")
    serial = state.serial
    transactionId = state.currentTransaction.id
    idToken = state.currentTransaction.idTag
    kwh = (meterStop - meterStart)/1000
    duration = Timex.diff(stop_datetime, start_datetime, :seconds)

    IO.puts "\n-------------------------------------------------------------"
    IO.puts "Session #{transactionId} on #{serial} with #{idToken}"
    IO.puts "-------------------------------------------------------------"
    IO.puts "Start: #{start_datetime}, Meter: #{meterStart}"
    IO.puts "Stop:  #{stop_datetime}, Meter: #{meterStop}"
    IO.puts "-------------------------------------------------------------"
    IO.puts "kWh: #{kwh}, Duration: #{duration}"
    IO.puts "-------------------------------------------------------------"
  end

end
