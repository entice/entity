defmodule Entice.AreaTest do
  use ExUnit.Case
  use Entice.Area
  alias Entice.Area
  alias Entice.Area.Entity

  defmodule TestAttr, do: defstruct foo: 1337

  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  test "worlds api", _ctx do
    {:ok, TeamArenas} = Area.get_map("TeamArenas")
  end

  test "entity api & events", _ctx do
    GenEvent.add_mon_handler(Area.Evt, Forwarder, self())

    # join and set attrib
    {:ok, id} = Entity.start(TeamArenas, UUID.uuid4())
    :ok = Entity.put_attribute(TeamArenas, id, %TestAttr{})
    assert Entity.has_attribute?(TeamArenas, id, TestAttr) == true

    assert_receive {:entity_added, TeamArenas, ^id}
    assert_receive {:attribute_updated, TeamArenas, ^id, %TestAttr{}}

    # change map
    Entity.change_area(TeamArenas, RandomArenas, id)
    assert_receive {:entity_removed, TeamArenas, ^id}
    assert_receive {:entity_added, RandomArenas, ^id}
  end
end
