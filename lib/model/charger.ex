defmodule Model.Charger do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    Charger Model
  """

  schema "charger" do
    field :serial,    :string
    field :pid,       :string
    field :status,    :string
    field :connected, :naive_datetime
    field :last_seen, :naive_datetime

    timestamps()
  end

  def changeset(charger, params \\ %{}) do
    charger
    	|> cast(params, [:serial, :pid, :status, :connected, :last_seen])
  end
end
