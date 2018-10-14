use Mix.Config

config :ocpp_backend, OcppBackendRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "ocpp_backend_dev",
  username: "postgres",
  password: "postgres"

config :mix_docker, image: "addictivesoftware/ocpp_backend"
