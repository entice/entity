defmodule Entice.AreaTest do
  use ExUnit.Case
  alias Entice.Area
  alias Entice.Area.Entity
  alias Entice.Area.TeamArenas

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

    {:ok, id} = Entity.start(TeamArenas, UUID.uuid4())
    :ok = Entity.put_attribute(TeamArenas, id, %TestAttr{})
    assert Entity.has_attribute?(TeamArenas, id, TestAttr) == true

    assert_receive {:entity_added, TeamArenas, ^id}
    assert_receive {:attribute_updated, TeamArenas, ^id, %TestAttr{}}
  end
end
