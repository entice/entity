defmodule Entice.Area.Geom.Maps do
  @moduledoc """
  Top-level map macros for convenient access to all defined maps.
  Is mainly used in area.ex where all the maps are defined.
  """

  defmacro __using__(_) do
    quote do
      import Entice.Area.Geom.Maps

      @maps []
      @before_compile Entice.Area.Geom.Maps
    end
  end


  defmacro defmap(mapname) do
    quote do
      @maps [ unquote(mapname) | @maps ]
      defmodule unquote(mapname), do: use Entice.Area.Geom.Maps.Map
    end
  end


  defmacro __before_compile__(env) do
    quote do
      # #adds an alias for all defined maps through using
      # defmacro __using__(_) do
      #   quote do
      #     unquote(for map <- @maps, do: alias unquote(map))
      #   end
      # end

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


  defmodule Map do
    @moduledoc """
    This macro puts all common map functions inside the map/area module that uses it
    """

    defmacro __using__(_) do
      quote do
        alias Entice.Area.Geom.Coord

        unquote(content)
        unquote(supervisor)
      end
    end

    defp content do
      quote do
        def spawn, do: %Coord{}
        def name, do: __MODULE__
        def underscore_name do
          unquote(__MODULE__ |> Module.split |> List.last |> to_string |> underscore)
        end

        defoverridable [name: 0, spawn: 0]
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

    defp underscore(string) do
      string
      |> String.to_char_list
      |> Enum.map(&underscore_char(&1))
      |> Enum.join("")
    end
    defp underscore_char(c) when c in ?a..?z, do: to_string(c)
    defp underscore_char(c) when c in ?A..?Z, do: "_" <> (c |> to_string |> String.downcase)
  end
end
