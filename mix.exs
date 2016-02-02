defmodule Entice.Entity.Mixfile do
  use Mix.Project

  def project do
    [app: :entice_entity,
     version: "0.0.1",
     elixir: "~> 1.2",
     deps: deps]
  end

  def application do
    [mod: {Entice.Entity.Application, []},
     applications: [:logger]]
  end

  defp deps do
    [{:entice_utils, github: "entice/utils", ref: "79ead4dca77324b4c24f584468edbaff2029eeab"},
     {:uuid, "~> 1.1"},
     {:inflex, "~> 1.5"}]
  end
end
