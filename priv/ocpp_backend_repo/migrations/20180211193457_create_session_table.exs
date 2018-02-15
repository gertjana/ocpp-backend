defmodule OcppBackendRepo.Migrations.CreateSessionTable do
  use Ecto.Migration

  def change do
		create table(:session) do
			add :transaction_id, 	:string, null: false
      add :serial, 					:string,	null: false
      add :token, 					:string, 	null: false
      add :start_time, 			:naive_datetime
      add :stop_time, 			:naive_datetime
      add :volume, 					:integer
      add :duration, 				:integer

      timestamps()
  	end
  	create unique_index(:session, [:transaction_id])
  end
end
