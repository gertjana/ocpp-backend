defmodule OcppBackendRepo.Migrations.AddConnectorIdToSessionAndCharger do
  use Ecto.Migration

  def change do
  	alter table(:session) do
  		add :connector_id, :string
  	end
  end
end
