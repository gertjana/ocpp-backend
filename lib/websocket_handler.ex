defmodule WebsocketHandler do
  @behaviour :cowboy_websocket
  @moduledoc """
  Handles websocket connections and negiotiating ocpp protocol (only 1.6 supported so far)
 """
  import Logger

  def init(req, _state) do
    sec_websocket_protocol = :cowboy_req.parse_header("sec-websocket-protocol", req)
    supported_version = cond do
      Enum.member?(sec_websocket_protocol, "ocpp2.0") -> {:ok, "ocpp2.0"}
      Enum.member?(sec_websocket_protocol, "ocpp1.6") -> {:ok, "ocpp1.6"}
      true -> {:not_supported, sec_websocket_protocol}
    end
  
    case supported_version do
      {:not_supported, protocol} -> 
        warn "No supported protocol version found in #{protocol}"
        {:shutdown, req}
      {:ok, version} ->
        serial = :cowboy_req.binding(:serial, req)
        state = %{:serial => serial, :id => 1, :version => version |> String.replace(".", "") |> String.to_atom}
        req2 = :cowboy_req.set_resp_header("sec-websocket-protocol", version, req)
        info "Negotiated #{version} for #{serial}"
        Chargepoints.subscribe(serial)
        {:cowboy_websocket, req2, state, %{:idle_timeout => 3_600 * 24 * 7}} # timeout is one week        
    end

    # case Enum.member?(:cowboy_req.parse_header("sec-websocket-protocol", req), "ocpp1.6") do
    #   true ->
    #     serial = :cowboy_req.binding(:serial, req)
    #     state = %{:serial => serial, :id => 1, :version => :ocpp16}
    #     req2 = :cowboy_req.set_resp_header("sec-websocket-protocol", "ocpp1.6", req)
    #     info "Negotiated ocpp1.6 for #{serial}"
    #     Chargepoints.subscribe(serial)
    #     {:cowboy_websocket, req2, state, %{:idle_timeout => 3_600 * 24 * 7}} # timeout is one week
    #   false ->
    #     {:shutdown, req}
    # end
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

    Ocpp.Messages.handle_message(message,state)
  end

  def websocket_info({:json, msg}, state) do
    {:ok, message} = JSX.encode(msg)
    {:reply, {:text, message}, state}
  end

end
