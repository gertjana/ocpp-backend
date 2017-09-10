defmodule WebsocketHandler do
  @behaviour :cowboy_websocket


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

  def terminate(_reason, _req, _state) do
    :ok
  end

  def websocket_handle({:text, content}, req, state) do
    {:ok, message} = JSX.decode(content) 
    {resp, new_state} = GenServer.call(OcppMessages, {message, state})
    {:reply, resp, req, new_state}
  end

  def websocket_info(_info, _req, state) do
    {:ok, state}
  end

end

