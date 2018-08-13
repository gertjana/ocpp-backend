defmodule ChargerCommandHandler do
  import Logger
  alias Ocpp.Commands

  @moduledoc """
    Module to handle command send via api calls
  """

  def init(req, state) do
    method = :cowboy_req.method(req)
    has_body = :cowboy_req.has_body(req)
    handle(method, has_body, req, state)
  end

  def handle("POST", true, request, state) do
    serial = :cowboy_req.binding(:serial, request)
    {:ok, body, request} = :cowboy_req.read_body(request)
    {:ok, command} = JSX.decode(body)

    case executeCommand(command["command"], command["data"], serial) do
      {:ok} ->
        request2 = :cowboy_req.reply(
          201,
          request
        )
        {:ok, request2, state}
      {:offline, message} ->
        request2 = :cowboy_req.reply(
          404,
          %{},
          message,
          request
        )
        {:ok, request2, state}
      {:not_allowed, message} ->
        request2 = :cowboy_req.reply(
          406,
          %{},
          message,
          request
        )
        {:ok, request2, state}
    end
  end

  defp executeCommand(command, data, serial) do
    case OnlineChargers.get(serial) do
      nil ->
        {:offline, "Chargepoint #{serial} is offline"}
      pid ->
        if Commands.command_allowed(command) do
          info "Sending reset command to #{serial}"
          GenServer.cast(Commands, {pid, command, data})
          {:ok}
        else
          {:not_allowed, "Command #{command} is not allowed"}
        end
      end
  end
end
