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
    [{:entice_utils, github: "entice/utils", ref: "e80039a439753d743635b0a67b78fa04329f8930"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.5"}]
  end
end
