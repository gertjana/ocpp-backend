defmodule OcppBackend.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
  Supervisor.init([
    OcppMessages,
    TokenAuthorisation,
    Chargepoints
  ], strategy: :one_for_one)
  end

end

