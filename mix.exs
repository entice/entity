defmodule Entice.Entity.Mixfile do
  use Mix.Project

  def project do
    [app: :entice_entity,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [mod: {Entice.Entity.Application, []},
     applications: [:logger]]
  end

  defp deps do
    [{:entice_utils, github: "entice/utils", ref: "4b743c4fe22eb4934221e69da2f50800347bcf32"},
     {:uuid, "~> 0.1.5"},
     {:inflex, "~> 0.2.5"}]
  end
end
