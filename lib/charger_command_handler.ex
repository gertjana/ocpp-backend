defmodule ChargerCommandHandler do
  import Logger

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

    executeCommand(command["command"], command["data"], serial)

    request = :cowboy_req.reply(
      201,
      %{"location" => "to be implemented"},
      request
    )
    {:ok, request, state}
  end

  defp executeCommand("Reset", data, serial) do
    case OnlineChargers.get(serial) do
      nil ->
        warn "Chargepoint #{serial} is offline"
      pid ->
        case data["type"] do
          "hard" -> GenServer.cast(Ocpp.Commands, {pid, :reset, "Hard"})
          "soft" -> GenServer.cast(Ocpp.Commands, {pid, :reset, "Soft"})
          x ->
            warn "No or unknown type: #{x} for Reset command"
        end
    end
  end
end
