use Mix.Config

config :ocpp_backend,
  ecto_repos: [OcppBackendRepo]

import_config "#{Mix.env}.exs"
