defmodule ApiHandlers.ChargerCommands do
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
      {:ok}                   -> {:ok, response(request, 201), state}
      {:offline, message}     -> {:ok, response(request, 404, message), state}
      {:not_allowed, message} -> {:ok, response(request, 406, message), state}
    end
  end

  defp response(request, statusCode \\ 200, message \\ "", headers \\ %{}) do
    :cowboy_req.reply(statusCode, headers, message, request)
  end

  defp executeCommand(command, data, serial) do
    case OnlineChargers.get(serial) do
      nil ->
        {:offline, "Chargepoint #{serial} is offline"}
      pid ->
        if Commands.command_allowed(command) do
          info "Sending #{command} command to #{serial}"
          GenServer.cast(Commands, {pid, command, data})
          {:ok}
        else
          {:not_allowed, "Command #{command} is not allowed"}
        end
      end
  end
end
