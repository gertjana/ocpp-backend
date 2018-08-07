defmodule OcppBackendRepo.Migrations.RemovePidColumnFromCharger do
  use Ecto.Migration

  def change do
alter table(:charger) do
  		remove :pid
  	end
  end
end
