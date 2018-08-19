defmodule Model.EvseConnector do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    Evse/Connector Model
  """

  schema "evse_connector" do
    field :serial,       :string
    field :evse_id,      :integer
    field :connector_id, :integer
    field :current_type, :string
    field :power_kwh,    :integer
    field :status,       :string, virtual: true

    timestamps()
  end

  def changeset(evse_connector, params \\ %{}) do
    evse_connector
    	|> cast(params, [:serial, :evse_id, :connector_id, :current_type, :power_kwh, :status])
  end
end
