defmodule Entice.Area.Maps do
  @moduledoc """
  Top-level map macros for convenient access to all defined maps.
  Is mainly used in area.ex where all the maps are defined.
  """

  defmacro __using__(_) do
    quote do
      import Entice.Area.Maps

      @maps []
      @before_compile Entice.Area.Maps
    end
  end


  defmacro defmap(mapname) do
    quote do
      defmodule unquote(mapname), do: use Entice.Area.Maps.Map
      @maps [ unquote(mapname) | @maps ]
    end
  end


  defmacro __before_compile__(_) do
    quote do
      unquote(inject_using)

      @doc """
      Simplistic map getter, tries to convert a map name to the module atom.
      The map should be a GW map name, without "Entice.Area.Worlds"
      """
      def get_map(name) do
        try do
          {:ok, ((__MODULE__ |> Atom.to_string) <> "." <> name) |> String.to_existing_atom}
        rescue
          ArgumentError -> {:error, :map_not_found}
        end
      end

      def get_maps, do: @maps
    end
  end


  def inject_using do
    quote unquote: false do
      #adds an alias for all defined maps through using
      defmacro __using__(_) do
        quote do
          unquote(for map <- @maps do
            quote do: alias unquote(map)
          end)
        end
      end
    end
  end
end


defmodule Entice.Area.Maps.Map do
  @moduledoc """
  This macro puts all common map functions inside the map/area module that uses it
  """
  import Inflex

  defmacro __using__(_) do
    quote do
      alias Entice.Area.Geom.Coord
      unquote(content(__CALLER__.module))
      unquote(supervisor)
    end
  end

  defp content(mod) do
    umod = underscore(mod |> Module.split |> List.last)
    quote do
      def spawn, do: %Coord{}
      def name, do: __MODULE__
      def underscore_name, do: unquote(umod)

      defoverridable [spawn: 0]
    end
  end

  defp supervisor do
    quote do
      sup_name = Module.concat(__MODULE__, "Sup")
      sup_contents = quote do
        def start_link, do: Entice.Area.Entity.Sup.start_link(unquote(__MODULE__))
      end

      Module.create(sup_name, sup_contents, Macro.Env.location(__ENV__))
    end
  end
end
