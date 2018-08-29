use Mix.Config

config :ocpp_backend, OcppBackendRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "ocpp_backend_test",
  username: "postgres",
  password: "postgres"

