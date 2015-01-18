defmodule Entice.Area.Attributes do
  alias Entice.Area.Geom.Coord

  defmacro __using__(_) do
    quote do
      alias Entice.Area.Geom.Coord
      alias Entice.Area.Attributes.Name
      alias Entice.Area.Attributes.Position
      alias Entice.Area.Attributes.Movement
      alias Entice.Area.Attributes.Appearance
      alias Entice.Area.Attributes.SkillBar
    end
  end

  defmodule Name, do: defstruct(name: "Hansus Wurstus")

  defmodule Position, do: defstruct(pos: %Coord{})

  defmodule Movement, do: defstruct(goal: %Coord{}, type: 9, speed: 1.0)

  defmodule Appearance, do: defstruct(
    profession: 1,
    campaign: 0,
    sex: 1,
    height: 0,
    skin_color: 3,
    hair_color: 0,
    hairstyle: 7,
    face: 30)

  defmodule SkillBar, do: defstruct(slots: %{})
end
