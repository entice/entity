defmodule Entice.Cynosure.EntityTest do
  use ExUnit.Case, async: false
  alias Entice.Cynosure.Entity

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false

  @world Entice.Cynosure.EntityTest.World1
  @world2 Entice.Cynosure.EntityTest.World2

  setup do
    # Set up a supervisor for entities of this world
    {:ok, _sup} = Entity.Sup.start_link(@world) # Takes a name for the world
    {:ok, _sup} = Entity.Sup.start_link(@world2)
    # Create a new entity: Choose and ID and attribute set
    {:ok, entity_id} = Entity.start(@world, UUID.uuid1(), %{TestAttr1 => %TestAttr1{}})
    {:ok, [entity: entity_id]}
  end


  test "world change", %{entity: entity_id} do
    assert Entity.exists?(@world, entity_id) == true
    assert Entity.exists?(@world2, entity_id) == false
    Entity.change_world(@world, @world2, entity_id)
    assert Entity.exists?(@world, entity_id) == false
    assert Entity.exists?(@world2, entity_id) == true
  end


  test "attribute adding", %{entity: entity_id} do
    Entity.put_attribute(@world, entity_id, %TestAttr2{})
    assert Entity.has_attribute?(@world, entity_id, TestAttr2) == true
  end


  test "attribute retrieval", %{entity: entity_id} do
    {:ok, %TestAttr1{}} = Entity.get_attribute(@world, entity_id, TestAttr1)
    :error = Entity.get_attribute(@world, entity_id, TestAttr2)

    Entity.put_attribute(@world, entity_id, %TestAttr2{})

    {:ok, %TestAttr1{}} = Entity.get_attribute(@world, entity_id, TestAttr1)
    {:ok, %TestAttr2{}} = Entity.get_attribute(@world, entity_id, TestAttr2)
  end


  test "attribute updateing", %{entity: entity_id} do
    {:ok, %TestAttr1{}} = Entity.get_attribute(@world, entity_id, TestAttr1)
    Entity.update_attribute(@world, entity_id, TestAttr1, fn _ -> %TestAttr1{foo: 42} end)
    {:ok, %TestAttr1{foo: 42}} = Entity.get_attribute(@world, entity_id, TestAttr1)

    :error = Entity.get_attribute(@world, entity_id, TestAttr2)
    Entity.update_attribute(@world, entity_id, TestAttr2, fn _ -> %TestAttr2{baz: true} end)
    :error = Entity.get_attribute(@world, entity_id, TestAttr2)
  end


  test "attribute removal", %{entity: entity_id} do
    assert Entity.has_attribute?(@world, entity_id, TestAttr1) == true
    Entity.remove_attribute(@world, entity_id, TestAttr1)
    assert Entity.has_attribute?(@world, entity_id, TestAttr1) == false
  end
end
