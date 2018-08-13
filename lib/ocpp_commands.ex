defmodule Ocpp.Commands do
  @moduledoc """
    This module handles all OCPP 1.6 Commands
  """
  use GenServer
  import Logger

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  defp allowed_commands, do: ["Reset","TriggerMessage"]

  def command_allowed(command), do: Enum.member?(allowed_commands(), command)

  def handle_cast({pid, command, data}, state) do
    send pid, {:json, [2, Utils.timestamp_as_string, command, data]}
    {:noreply, state}
  end
end
