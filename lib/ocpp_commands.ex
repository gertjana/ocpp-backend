defmodule OcppCommands do
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

  def handle_call({{pid, :reset, resetType}, _state}, _sender, _current_state) do
    send pid, [2, Utils.timestamp_as_string, "Reset", %{"resetType" => resetType}]
  end
end
