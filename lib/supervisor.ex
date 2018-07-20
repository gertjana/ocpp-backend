defmodule OcppBackend.Supervisor do
  use Supervisor

  @moduledoc """
    Supervises all modules in the application
  """

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do

    children =  [
      worker(OcppBackendRepo, []),
      OcppMessages,
      TokenAuthorisation,
      Chargepoints,
      Chargetokens,
      Chargesessions
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
