defmodule Entice.Cynosure.WorldTest do
  use ExUnit.Case
  alias Entice.Cynosure.World
  alias Entice.Cynosure.Entity

  setup do
    {:ok, manager} = GenEvent.start_link()
    {:ok, sup} = Entity.Supervisor.start_link()
    {:ok, world} = World.start_link(manager, sup)
    {:ok, [world: world]}
  end


  test "entity creation", %{world: world} do
    {:ok, entity_id, entity} = World.create_entity(world)
    assert entity_id != ""
    {:ok, entity_id, entity} = World.lookup_entity(world, entity_id)
  end
end
