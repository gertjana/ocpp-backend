defmodule Ocpp.Messages.V20 do
  alias Ocpp.Messages, as: Messages
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

  # Callbacks
# Authorize
# TransactionEvent
# StatusNotification
# Reset (only IMMEDIATE reset is supported)
# GetVariables (will return REJECTED status)
# SetVariables (will return ACCEPTED, but does not store variables anywhere)

  def handle_call({[2, id, "BootNotification", _], state}, _sender, current_state) do
    {state, {:ok, reply}} = handle_boot_notification(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({[2, id, "Heartbeat", _], state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_heartbeat(id, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  def handle_call({message, state}, _sender, current_state) do
    {state, {:ok, reply}} = Messages.handle_notimplemented(message, state)
    {:reply, {{:text, reply}, state}, current_state}
  end

  # Implementations

  defp handle_boot_notification(id, state) do
    {state, JSX.encode([3, id, [currentTime: Utils.datetime_as_string]])}
  end

end
