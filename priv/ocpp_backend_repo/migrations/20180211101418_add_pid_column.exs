defmodule OcppBackendRepo.Migrations.AddPidColumn do
  use Ecto.Migration

  def change do
  	alter table(:charger) do
  		add :pid, :string
  	end
  end
end
