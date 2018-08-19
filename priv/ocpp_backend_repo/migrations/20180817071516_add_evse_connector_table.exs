defmodule OcppBackendRepo.Migrations.AddEvseConnectorTable do
  use Ecto.Migration

  def change do
    create table(:evse_connector) do
      add :serial, 			:string,	null: false
      add :evse_id, 		:integer, 	null: false
      add :connector_id, 	:integer, 	null: false
      add :current_type, 	:string, 	null: false
      add :power_kwh, 		:integer, 	null: false

      timestamps()
	  end
	end
end
