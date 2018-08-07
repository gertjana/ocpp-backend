defmodule WebsocketHandler do
  @behaviour :cowboy_websocket
  @moduledoc """
  Handles websocket connections and negiotiating ocpp protocol (only 1.6 supported so far)
 """
  import Logger

  def init(req, _state) do
    info "Initializing WebSocketconnection for #{inspect(self())}"
    case Enum.member?(:cowboy_req.parse_header("sec-websocket-protocol", req), "ocpp1.6") do
      true ->
        serial = :cowboy_req.binding(:serial, req)
        state = %{:serial => serial, :id => 1}
        req2 = :cowboy_req.set_resp_header("sec-websocket-protocol", "ocpp1.6", req)
        info "Negotiated ocpp1.6 for #{serial}"
        GenServer.call(Chargepoints, {:subscribe, serial, self()})
        {:cowboy_websocket, req2, state}
      false ->
        {:shutdown, req}
    end
  end

  def terminate(_reason, _req, state) do
    info "Terminating"
    case state.serial do
      nil ->
        info "Undefined serial"
        info "state #{inspect(state)}"
        :ok
      serial ->
        info "marking #{serial} offline"
        GenServer.call(Chargepoints, {:unsubscribe, serial})
        :ok
    end
  end

  def websocket_handle({:text, content}, state) do
    {:ok, message} = JSX.decode(content)
    serial = state[:serial]
    GenServer.call(Chargepoints, {:message_seen, serial})
    {resp, new_state} = GenServer.call(Ocpp.Messages, {message, state})
    {:reply, resp, new_state}
  end

  def websocket_info(msg, state) do
    {:ok, message} = JSX.encode(msg)
    {:reply, {:text, message}, state}
  end
end
