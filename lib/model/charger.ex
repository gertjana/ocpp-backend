defmodule Model.Charger do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    Charger Model
  """

  schema "charger" do
    field :serial,    :string
    field :protocol,  :string
    field :connected, :naive_datetime
    field :last_seen, :naive_datetime
    field :online,    :boolean, virtual: true

    timestamps()
  end

  def changeset(charger, params \\ %{}) do
    charger
    	|> cast(params, [:serial, :protocol, :connected, :last_seen])
  end
end
