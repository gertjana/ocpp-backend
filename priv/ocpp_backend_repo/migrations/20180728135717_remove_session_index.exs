defmodule OcppBackendRepo.Migrations.RemoveSessionIndex do
  use Ecto.Migration

  def change do
	drop index(:session, [:transaction_id])
  end
end
