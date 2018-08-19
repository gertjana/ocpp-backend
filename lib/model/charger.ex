defmodule Model.Charger do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    Charger Model
  """

  schema "charger" do
    field :serial,    :string
    field :connected, :naive_datetime
    field :last_seen, :naive_datetime

    timestamps()
  end

  def changeset(charger, params \\ %{}) do
    charger
    	|> cast(params, [:serial, :connected, :last_seen])
  end
end
