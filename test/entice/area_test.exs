defmodule Entice.AreaTest do
  use ExUnit.Case
  alias Entice.Area
  alias Entice.Area.Entity
  alias Entice.Area.TeamArenas

  defmodule TestAttr, do: defstruct foo: 1337

  setup_all do
    {:ok, _sup} = Entice.Area.Sup.start_link
    :ok
  end

  test "worlds api", _ctx do
    {:ok, TeamArenas} = Area.get_map("TeamArenas")
  end

  test "entity api", _ctx do
    {:ok, id} = Entity.start(TeamArenas, UUID.uuid4())
    :ok = Entity.put_attribute(TeamArenas, id, %TestAttr{})
    assert Entity.has_attribute?(TeamArenas, id, TestAttr) == true
  end
end
