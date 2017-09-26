defmodule WebsocketHandler do
  @behaviour :cowboy_websocket
  import Logger

  def init(req, _state) do
    info "Initializing WebSocketconnection for #{inspect(self())}"
    case Enum.member?(:cowboy_req.parse_header("sec-websocket-protocol", req), "ocpp1.6") do
      true -> 
        state = %{:serial => :cowboy_req.binding(:serial, req), :id => 1}
        req2 = :cowboy_req.set_resp_header("sec-websocket-protocol", "ocpp1.6", req)
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

  def websocket_info(msg, req, state) do
    {:ok, message} = JSX.encode(msg)
    {:reply, {:text, message}, req, state}
  end
end

