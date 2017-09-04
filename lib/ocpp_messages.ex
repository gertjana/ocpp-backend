defmodule OcppMessages do

  def handle([2, id, "BootNotification", _], req, state) do
    {:ok, reply} = JSX.encode([3,id, [status: "Accepted", currentTime: Utils.time_as_string, heartbeatInterval: 300]])
    {:reply, {:text, reply}, req, state}
  end

  def handle([2, id, "Heartbeat"], req, state) do
    {:ok, reply} = JSX.encode([3, id, [currentTime: Utils.time_as_string]])
    {:reply, {:text, reply}, req, state}
  end

  def handle([2, id, "Authorize",%{"idToken" => idToken}], req, state) do
    {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idToken]]])
    {:reply, {:text, reply}, req, state}
  end

  def handle([2, id, "StartTransaction", %{"connectorId" => _, "idTag" => idToken, "meterStart" => meterStart, "timestamp" => timestamp}], req, state) do
    case state do
      %{:currentTransaction => _} ->
        {:ok, reply} = JSX.encode([4, id, "Transaction Already started", "A session is still undergoing on this chargepoint"])  
        {:reply, {:text, reply}, req, state}
      _ -> 
      {state, transactionId} =  next_transaction_id(state)
      state = Map.put(state, :currentTransaction, %{id: transactionId, start: meterStart, timestamp: timestamp, idTag: idToken})
      
      {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idToken], transactionId: transactionId]])
      {:reply, {:text, reply}, req, state}
    end 
  end

  def handle([2, id, "StopTransaction", %{"idTag" => idToken, "meterStop" => meterStop, "timestamp" => timestamp}], req, state) do
    case state do
      %{:currentTransaction => _} ->
        storeTransaction(state, meterStop, timestamp)
        state = Map.delete(state, :currentTransaction)
        {:ok, reply} = JSX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idToken]]])
        {:reply, {:text, reply}, req, state}
      _ ->
        {:ok, reply} = JSX.encode([4, id, "Transaction not started", "you can't stop a transaction that hasn't been started"])
        {:reply, {:text, reply}, req, state}
    end
  end

  #fallback handler, valid json, but we do not yet understand it
  def handle(_, req, state) do
    {:ok, reply} = JSX.encode([4, "", "Not Implemented", "This backend does not understand this message (yet)"])  
    {:reply, {:text, reply}, req, state}
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
