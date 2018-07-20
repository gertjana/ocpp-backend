defmodule OcppBackend do
  import Logger
  import Utils

  @moduledoc """
    Main entrypoint of the Application
  """

  def start(_type, _args) do

    port = System.get_env("PORT")
            |> default("8383")
            |> String.to_integer

    info "Starting OCPP Backend application on #{port}"

    dispatch_config = build_dispatch_config()
    {:ok, _} = :cowboy.start_http(:http,
                                    32, #4096
                                   [{:port, port}],
                                   [{:env, [{:dispatch, dispatch_config}]}]
                                   )
    OcppBackend.Supervisor.start_link
  end

  def build_dispatch_config do
    :cowboy_router.compile([
      {:_,
        [
          {"/static/[...]", :cowboy_static, {:priv_dir,  :ocpp_backend, "static_files"}},
          {"/client", WebsocketClientPageHandler, []},
          {"/chargers", DashboardPageHandler, []},
          {"/chargers/:serial", ChargerPageHandler, []},
          {"/ocppws/:serial", WebsocketHandler, []}
      ]}
    ])
  end
end
