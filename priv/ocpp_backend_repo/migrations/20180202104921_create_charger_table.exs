defmodule OcppBackend.Repo.Migrations.CreateChargerTable do
  use Ecto.Migration

  def change do
  	create table(:charger) do
      add :serial, 		:string,	null: false
      add :status, 		:string, 	null: false, deault: "Unknown"
      add :connected, :naive_datetime
      add :last_seen, :naive_datetime

      timestamps()
    end

    create unique_index(:charger, [:serial])
  end
end
