defmodule Entice.Cynosure.Attributes do
  alias Entice.Cynosure.Geom.Coord

  defmodule Name,     do: defstruct name: "Unnamed"
  defmodule Position, do: defstruct pos: %Coord{}
end
