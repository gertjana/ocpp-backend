defmodule OcppBackendRepo.Migrations.RemoveTransactionIdFromSessionTable do
  use Ecto.Migration

  def change do
    alter table(:session) do
      remove :transaction_id
    end
  end
end
