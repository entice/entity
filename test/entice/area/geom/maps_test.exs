defmodule Entice.Area.Geom.MapsTest do
  use Entice.Area.Geom.Maps
  use ExUnit.Case

  defmap SomeMap

  test "map name" do
    assert SomeMap.name == SomeMap
  end

  test "map underscore name" do
    assert SomeMap.underscore_name == "some_map"
  end
end
