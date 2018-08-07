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

  def handle_cast({pid, :reset, reset_type}, current_state) do
    info "Sending command to #{inspect(pid)}"
    send pid, [2, Utils.timestamp_as_string, "Reset", %{"resetType" => reset_type}]
    {:noreply, current_state}
  end
end
