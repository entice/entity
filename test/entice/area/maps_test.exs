defmodule Entice.Area.MapsTest do
  use Entice.Area.Maps
  use ExUnit.Case

  defmap SomeMap


  # Create some maps and...
  defmodule SomeMaps do
    use Entice.Area.Maps

    defmap SomeMap
    defmap SomeOtherMap
  end
  # ...test if the using works
  defmodule UsingSomeMaps do
    use SomeMaps

    def test, do: SomeMap.name
  end


  test "map name" do
    assert SomeMap.name == "SomeMap"
  end

  test "map underscore name" do
    assert SomeMap.underscore_name == "some_map"
  end

  test "test __using__ macros compilation" do
    assert UsingSomeMaps.test == SomeMaps.SomeMap.name
  end
end
