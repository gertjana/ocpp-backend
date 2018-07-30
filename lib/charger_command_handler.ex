defmodule ChargerCommandHandler do
  import Logger

  @moduledoc """
    Module to handle command send via api calls
  """

  def init(request, options \\ []) do
    {:cowboy_rest, request, options}
  end

  def content_types_provided(request, state) do
    {[{"application/json", :to_json}], request, state}
  end

  def to_json(request, state) do
    serial = :cowboy_req.binding(:serial, request)
    command = :cowboy_req.binding(:command, request)
    executeCommand(serial, command)
    {"{\"#{serial}\":\"#{command}\"}", request, state}
  end

  defp executeCommand(serial, command) do
    {:ok, charger} = GenServer.call(Chargepoints, {:subscriber, serial})
    case command do
      "reset_hard" -> GenServer.call(OcppCommands, {charger.pid, :reset, "Hard"})
      "reset_soft" -> GenServer.call(OcppCommands, {charger.pid, :reset, "Soft"})

      _ -> warn "Unknown command"
    end
  end
end
