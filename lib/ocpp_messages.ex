defmodule Ocpp.Messages do
  alias Ocpp.Messages.V16, as: V16
  alias Ocpp.Messages.V20, as: V20
  @moduledoc """
    This module forward all OCPP messages to the respective versions
  """

  def handle_message(message, state) do
    case state.version do
      :ocpp20 -> V20.handle_message(message, state)
      :ocpp16 -> V16.handle_message(message, state)
      _ -> {:error, "Unknown version #{state.version}"}
    end
  end

  # Generic implementations called from the version specific modules

  def handle_default(id, state) do
    {state, JSX.encode([3, id, []])}
  end

  def handle_notimplemented(id, state) do
    {state,  JSX.encode([4, id, [status: "Rejected", data: "Not Implemented"]])}
  end

  def handle_heartbeat(id, state) do
    {state, JSX.encode([3, id, [currentTime: Utils.datetime_as_string]])}
  end
end
