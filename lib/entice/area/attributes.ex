defmodule Entice.Area.Attributes do
  alias Entice.Area.Geom.Coord

  defmacro __using__(_) do
    quote do
      alias Entice.Area.Attributes.Name
      alias Entice.Area.Attributes.Position
    end
  end

  defmodule Name,     do: defstruct name: "Unnamed"
  defmodule Position, do: defstruct pos: %Coord{}
end
