defmodule Ocpp.Messages.V20 do
  @moduledoc """
    This module handles all OCPP 2.0 messages
  """
  use GenServer
  import Logger

    def init(args) do
    {:ok, args}
  end

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  # Client calls

  def handle_message(message, state) do
    case GenServer.call(Ocpp.Messages.V20, {message, state}) do
      {{:ok, _}, new_state} -> {:ok, new_state}
      {resp, new_state} -> {:reply, resp, new_state}
    end
  end

  def handle_call({message, state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_default(message, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  defp handle_default(message, state) do
    {state, JSX.encode([4, 0, [status: "Rejected", data: "Not Implemented"]])}
  end
end
