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


  defmodule Map do
    @moduledoc """
    This macro puts all common map functions inside the map/area module that uses it
    """

    defmacro __using__(_) do
      quote do
        alias Entice.Area.Geom.Coord

        @mod
        unquote(content)
        unquote(supervisor)
      end
    end

    defp content do
      quote do
        unquote underscore

        def spawn, do: %Coord{}
        def name, do: __MODULE__
        def underscore_name do
          name |> Module.split |> List.last |> to_string |> underscore
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

    def underscore(value) when not is_binary(value) do
      underscore(to_string(value))
    end


    # Taken from the phoenix framework: https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/naming.ex#L78
    def underscore do
      quote do
        def underscore(""), do: ""
        def underscore(<<h, t :: binary>>), do: <<to_lower_char(h)>> <> do_underscore(t, h)

        defp do_underscore(<<h, t, rest :: binary>>, _) when h in ?A..?Z and not t in ?A..?Z do
          <<?_, to_lower_char(h), t>> <> do_underscore(rest, t)
        end

        defp do_underscore(<<h, t :: binary>>, prev) when h in ?A..?Z and not prev in ?A..?Z do
          <<?_, to_lower_char(h)>> <> do_underscore(t, h)
        end

        defp do_underscore(<<?-, t :: binary>>, _) do
          <<?_>> <> do_underscore(t, ?-)
        end

        defp do_underscore(<< "..", t :: binary>>, _) do
          <<"..">> <> underscore(t)
        end

        defp do_underscore(<<?.>>, _), do: <<?.>>

        defp do_underscore(<<?., t :: binary>>, _) do
          <<?/>> <> underscore(t)
        end

        defp do_underscore(<<h, t :: binary>>, _) do
          <<to_lower_char(h)>> <> do_underscore(t, h)
        end

        defp do_underscore(<<>>, _) do
          <<>>
        end

        defp to_lower_char(char) when char in ?A..?Z, do: char + 32
        defp to_lower_char(char), do: char
      end
    end
  end
end
