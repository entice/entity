defmodule Entice.Cynosure.Mixfile do
  use Mix.Project

  def project do
    [app: :entice_cynosure,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  #def application do
  #  [applications: [:logger],
  #   mod: {Entice.Cynosure, []}]
  #end

  defp deps do
    [{:uuid, "~> 0.1.5"}]
  end
end
