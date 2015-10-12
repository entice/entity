defmodule Entice.Entity.Mixfile do
  use Mix.Project

  def project do
    [app: :entice_entity,
     version: "0.0.1",
     elixir: "~> 1.1",
     deps: deps]
  end

  def application do
    [mod: {Entice.Entity.Application, []},
     applications: [:logger]]
  end

  defp deps do
    [{:entice_utils, github: "entice/utils", ref: "74ce9f8a2e2fd7766263e193bffba4901aa425a8"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.5"}]
  end
end
