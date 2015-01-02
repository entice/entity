defmodule Entice.Cynosure.Worlds do

  defmodule World do
    @moduledoc """
    This macro puts all common world functions inside the module that uses it
    """

    defmacro __using__(_) do
      quote do
        # Define the module content
        alias Entice.Cynosure.Geom.Coord

        def name, do: __MODULE__
        def spawn, do: %Coord{}

        defoverridable [name: 0, spawn: 0]

        # Define a supervisor
        sup_name = Module.concat(__MODULE__, "Sup")
        sup_contents = quote do
          def start_link, do: Entice.Cynosure.Entity.Sup.start_link(unquote(__MODULE__))
        end

        Module.create(sup_name, sup_contents, Macro.Env.location(__ENV__))
      end
    end
  end


  defmodule HeroesAscent, do: use World
  defmodule RandomArenas, do: use World
  defmodule TeamArenas, do: use World


  @doc """
  Simplistic world getter, tries to convert a world name to the module atom.
  The world should be a GW world name, without "Entice.Cynosure.Worlds"
  """
  def get_world(name) do
    try do
      {:ok, ((__MODULE__ |> Atom.to_string) <> "." <> name) |> String.to_existing_atom}
    rescue
      ArgumentError -> {:error, :world_not_found}
    end
  end
end


defmodule Entice.Cynosure.Worlds.Sup do
  use Supervisor

  def start_link, do: Supervisor.start_link(__MODULE__, :ok)

  def init(:ok) do
    children = [
      supervisor(Entice.Cynosure.Worlds.HeroesAscent.Sup, []),
      supervisor(Entice.Cynosure.Worlds.RandomArenas.Sup, []),
      supervisor(Entice.Cynosure.Worlds.TeamArenas.Sup, [])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
