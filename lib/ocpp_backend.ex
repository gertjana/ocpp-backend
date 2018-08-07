defmodule OcppBackend do
  use Application
  import Logger
  import Utils

  @moduledoc """
    Main entrypoint of the Application
  """

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    port = System.get_env("PORT")
            |> default("8383")
            |> String.to_integer

    info "Starting OCPP Backend application on #{port}"

    dispatch = :cowboy_router.compile routes()

    {:ok, _} = :cowboy.start_clear(:http,
                                   [{:port, port}],
                                   %{env: %{dispatch: dispatch}}
                                   )
    OcppBackend.Supervisor.start_link
  end

  defp routes do
    [{:_, static_routes() ++ websocket_routes() ++ page_routes() ++ api_routes()}]
  end

  defp static_routes do
    [{"/static/[...]", :cowboy_static, {:priv_dir,  :ocpp_backend, "static_files"}}]
  end

  defp websocket_routes do
    [{"/ocppws/:serial", WebsocketHandler, []}]
  end

  defp page_routes do
    [{"/client", WebsocketClientPageHandler, []},
    {"/chargers", DashboardPageHandler, []},
    {"/chargers/:serial", ChargerPageHandler, []}]
  end

  defp api_routes do
    [{"/api/chargers/:serial/command", ChargerCommandHandler, []}]
  end
end
