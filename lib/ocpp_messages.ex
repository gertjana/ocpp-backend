defmodule Ocpp.Messages do
  @moduledoc """
    This module forward all OCPP messages to the respective versions
  """

  def handle_message(message, state=%{serial: _, id: _, version: version}) do
    case version do
      :ocpp16 -> Ocpp.Messages.V16.handle_message(message, state)
      :ocpp20 -> Ocpp.Messages.V20.handle_message(message, state)
      _ -> {:error, "Unknown version #{version}"}
    end
  end
end