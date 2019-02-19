defmodule WebsocketHandler do
  alias Ocpp.Messages, as: Messages
  @behaviour :cowboy_websocket
  @moduledoc """
  Handles websocket connections and negiotiating ocpp protocol (only 1.6 supported so far)
 """
  import Logger

  def init(req, _state) do
    sec_websocket_protocol = :cowboy_req.parse_header("sec-websocket-protocol", req)
    agreed_protocol = cond do
      Enum.member?(sec_websocket_protocol, "ocpp2.0") -> {:ok, "ocpp2.0"}
      Enum.member?(sec_websocket_protocol, "ocpp1.6") -> {:ok, "ocpp1.6"}
      true -> {:not_supported, sec_websocket_protocol}
    end

    case agreed_protocol do
      {:not_supported, protocol} ->
        warn "No supported protocol version found in #{protocol}"
        {:shutdown, req}
      {:ok, protocol} ->
        serial = :cowboy_req.binding(:serial, req)
        state = %{:serial => serial, :id => 1, :version => protocol |> String.replace(".", "") |> String.to_atom}
        req2 = :cowboy_req.set_resp_header("sec-websocket-protocol", protocol, req)
        info "Negotiated #{protocol} for #{serial}"
        Chargepoints.subscribe(serial, protocol)
        {:cowboy_websocket, req2, state, %{:idle_timeout => 3_600 * 24 * 7}} # timeout is one week
    end
  end

  def websocket_init(state) do
    info "Initializing WebSocketconnection for #{inspect(self())}"
    OnlineChargers.put(state.serial, self())
    {:ok, state}
  end

  def terminate(_reason, _req, state) do
    info "Terminating"
    case state.serial do
      nil ->
        :ok
      serial ->
        OnlineChargers.delete(serial)
        Chargepoints.unsubscribe(serial)
        :ok
    end
  end

  def websocket_handle({:text, content}, state) do
    {:ok, message} = JSX.decode(content)
    serial = state[:serial]
    Chargepoints.message_seen(serial)
    info inspect(message)

    Messages.handle_message(message, state)
  end

  def websocket_info({:json, msg}, state) do
    {:ok, message} = JSX.encode(msg)
    {:reply, {:text, message}, state}
  end

end
