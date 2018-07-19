defmodule OcppBackend.Mixfile do
  use Mix.Project

  def project do
    [app: :ocpp_backend,
     version: "0.0.3",
     elixir: ">= 1.0.0",
     elixirc_paths: ["lib", "lib/model"],
     deps: deps()]
  end

  def application do
    [
      mod: { OcppBackend, [] },
      applications: [:cowboy, :ranch, :timex, :postgrex, :ecto],
      included_applications:  [:exjsx, :uuid]
    ]
  end

  defp deps do
    [ { :cowboy, github: "ninenines/cowboy", tag: "2.0.0-pre.3" },
      { :exjsx,       "~> 3.0.0" },
      { :uuid,        "~> 1.1" },
      { :timex,       "~> 3.0" },
      { :distillery,  "~> 1.0" },
      { :postgrex,    "0.13.3" },
      { :ecto,        "~> 2.2.8" } ]
  end
end
