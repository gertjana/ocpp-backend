defmodule OcppBackend.Mixfile do
  use Mix.Project

  def project do
    [app: :ocpp_backend,
     version: "0.0.3",
     elixir: ">= 1.0.0",
     deps: deps()]
  end

  def application do
    [
      mod: { OcppBackend, [] },
      applications: [:cowboy, :ranch, :timex, :postgrex, :ecto]
    ]
  end

  defp deps do
    [ { :cowboy, github: "ninenines/cowboy", tag: "2.0.0-pre.3" },
      { :exjsx,       "~> 3.0.0" },
      { :uuid,        "~> 1.1" },
      { :timex,       "~> 3.0"},
      { :distillery,  "~> 1.0"},
      { :postgrex,    "0.10.0"},
      { :ecto,        "~> 1.0"} ]
  end
end
