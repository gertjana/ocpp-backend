defmodule Ocpp.Messages do
  alias Ocpp.Messages.V16, as: V16
  alias Ocpp.Messages.V20, as: V20
  @moduledoc """
    This module forward all OCPP messages to the respective versions
  """

  def handle_message(message, state=%{serial: _, id: _, version: version}) do
    case version do
      :ocpp20 -> V20.handle_message(message, state)
      :ocpp16 -> V16.handle_message(message, state)
      _ -> {:error, "Unknown version #{version}"}
    end
  end
end
