defmodule Entice.Cynosure.WorldsTest do
  use ExUnit.Case
  alias Entice.Cynosure.Entity
  alias Entice.Cynosure.Worlds
  alias Entice.Cynosure.Worlds.TeamArenas

  defmodule TestAttr, do: defstruct foo: 1337

  setup_all do
    {:ok, _sup} = Entice.Cynosure.Worlds.Sup.start_link
    :ok
  end

  test "worlds api", _ctx do
    {:ok, TeamArenas} = Worlds.get_world("TeamArenas")
  end

  test "entity api", _ctx do
    {:ok, id} = Entity.start(TeamArenas, UUID.uuid1())
    :ok = Entity.put_attribute(TeamArenas, id, %TestAttr{})
    assert Entity.has_attribute?(TeamArenas, id, TestAttr) == true
  end
end
