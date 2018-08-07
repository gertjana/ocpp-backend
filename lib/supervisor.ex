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
      Ocpp.Messages,
      Ocpp.Commands,
      TokenAuthorisation,
      Chargepoints,
      Chargetokens,
      Chargesessions,
      worker(OnlineChargers, [])
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
