defmodule OcppBackendRepo.Migrations.AddProtocolColumnToChargerTable do
  use Ecto.Migration

  def change do
    alter table(:charger) do
      add :protocol, :string
    end
  end
end
