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
      case Enum.member?(:cowboy_req.parse_header("sec-websocket-protocol", req), "ocpp16") do
        true -> 
          state = %{:serial => :cowboy_req.binding(:serial, req), :id => 1}
          req2 = :cowboy_req.set_resp_header("sec-websocket-protocol", "ocpp16", req)
          {:cowboy_websocket, req2, state}          
        false ->
          {:shutdown, req}
      end
  end

  # Put any essential clean-up here.
  def terminate(_reason, _req, _state) do
    :ok
  end

  # Generic handlers just decodes from json content
  def websocket_handle({:text, content}, req, state) do
    {:ok, message} = JSEX.decode(content)
    OcppMessages.handle(message, req, state)
  end

  # websocket_info is the required callback that gets called when erlang/elixir
  # messages are sent to the handler process. 
  # In a larger app various clauses of websocket_info might handle all kinds
  # of messages and pass information out the websocket to the client.
  def websocket_info(_info, _req, state) do
    {:ok, state}
  end

end

