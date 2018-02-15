defmodule OcppBackend.Repo.Migrations.AddToken do
  use Ecto.Migration

  def change do
  	create table(:token) do
      add :token, 		:string,	null: false
      add :provider, 	:string, 	null: false, size: 40
      add :description, :string, 	size: 80
      add :blocked, 	:boolean, 	default: false

      timestamps()
    end

    create unique_index(:token, [:token, :provider])
  end
end
