defmodule WebsocketHandler do
  @behaviour :cowboy_websocket
  
  # We are using the regular http init callback to perform handshake.
  #     http://ninenines.eu/docs/en/cowboy/2.0/manual/cowboy_handler/
  #
  # Note that handshake will fail if this isn't a websocket upgrade request.
  # Also, if your server implementation supports subprotocols,
  # init is the place to parse `sec-websocket-protocol` header
  # then add the same header to `req` with value containing
  # supported protocol(s).
  def init(req, _state) do
    serial = :cowboy_req.binding(:serial, req)
    state = %{}
    Map.put(state, :serial, serial)
    Map.put(state, :id, 1)
    :erlang.start_timer(1000, self, [])
    {:cowboy_websocket, req, state}
  end

  # Put any essential clean-up here.
  def terminate(_reason, _req, _state) do
    :ok
  end

  #Generic handlers just decodes from json content
  def websocket_handle({:text, content}, req, state) do
    {:ok, %{ "message" => message}} = JSEX.decode(content)
    handleOcppMessage(message, req, state)
  end

  # OCPP Message handlers
  defp handleOcppMessage([2, id, "BootNotification", _], req, state) do
    {:ok, reply} = JSEX.encode([3,id, [status: "Accepted", currentTime: time_as_string, heartbeatInterval: 300]])
    {:reply, {:text, reply}, req, state}
  end

  defp handleOcppMessage([2, id, "Authorize",%{"idToken" => idToken}], req, state) do
    {:ok, reply} = JSEX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idToken]]])
    {:reply, {:text, reply}, req, state}
  end

  defp handleOcppMessage([2, id, "Heartbeat"], req, state) do
    IO.puts "got a hearbeat"
    {:ok, reply} = JSEX.encode([3, id, [currentTime: time_as_string]])
    {:reply, {:text, reply}, req, state}
  end

  defp handleOcppMessage([2, id, "StartTransaction", %{"connectorId" => _, "idTag" => idToken, "meterStart" => meterStart, "timestamp" => timestamp}], req, state) do
    #TODO check if no transaction active
    {state, transactionId} =  next_transaction_id(state)
    Map.put(state, :currentTransaction, %{id: transactionId, start: meterStart, timestamp: timestamp, idTag: idToken})
    
    {:ok, reply} = JSEX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idToken], transactionId: transactionId]])
    {:reply, {:text, reply}, req, state}
  end

  defp handleOcppMessage([2, id, "StopTransaction", %{"idTag" => idToken, "meterStop" => meterStop, "timestamp" => timestamp}], req, state) do
    #TODO check same token
    storeTransaction(state, meterStop, timestamp)
    #TODO clear state
    {:ok, reply} = JSEX.encode([3, id, [idTagInfo: [status: "Accepted", idToken: idToken]]])
    {:reply, {:text, reply}, req, state}
  end

  #fallback handler, valid json, but we do not yet understand it
  defp handleOcppMessage(_, req, state) do
    {:ok, reply} = JSEX.encode([4, "", "Not Implemented", "This backend does not understand this message (yet)"])  
    {:reply, {:text, reply}, req, state}
  end

  # websocket_info is the required callback that gets called when erlang/elixir
  # messages are sent to the handler process. In this example, the only erlang
  # messages we are passing are the :timeout messages from the timing loop.
  #
  # In a larger app various clauses of websocket_info might handle all kinds
  # of messages and pass information out the websocket to the client.
  def websocket_info({_timeout, _ref, _msg}, req, state) do

    time = time_as_string()

    # encode a json reply in the variable 'message'
    { :ok, message } = JSEX.encode(%{ time: time})

    # set a new timer to send a :timeout message back to this
    # process a second from now. This will recursively call
    # this handler, acting as a tick.
    :erlang.start_timer(1000, self, [])

    # send the new message to the client. Note that even though there was no
    # incoming message from the client, we still call the outbound message
    # a 'reply'.  That makes the format for outbound websocket messages
    # exactly the same as websocket_handle()
    { :reply, {:text, message}, req, state}
  end

  # fallback message handler
  def websocket_info(_info, _req, state) do
    {:ok, state}
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
    IO.puts "Stop: #{stop_datetime}, Meter: #{meterStop}"
    IO.puts "-------------------------------------------------------------"
    IO.puts "kWh: #{kwh}, Duration: #{duration}"
    IO.puts "-------------------------------------------------------------"
  end


  defp next_transaction_id(state) do
    state = %{state | :id => state.id + 1}
    {state, state.serial <> "_" <> Integer.to_string(state.id)}
  end

  defp time_as_string do
    {hh, mm, ss} = :erlang.time()
    :io_lib.format("~2.10.0B:~2.10.0B:~2.10.0B", [hh, mm, ss])
    |> :erlang.list_to_binary()
  end

end

