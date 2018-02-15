defmodule Model.Token do
  use Ecto.Schema
  import Ecto.Changeset

  schema "token" do
    field :token,       :string
    field :provider,    :string
    field :description, :string
    field :blocked,     :boolean

    timestamps()
  end

  def changeset(token, params \\ %{}) do
    token
    	|> cast(params, [:token, :provider, :description, :blocked])
  end
end
