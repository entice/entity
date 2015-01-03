defmodule Entice.Area.EntityTest do
  use ExUnit.Case, async: false
  alias Entice.Area.Entity

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false

  @map Entice.Area.EntityTest.Map1
  @map2 Entice.Area.EntityTest.Map2

  setup do
    # Set up a supervisor for entities of this map
    {:ok, _sup} = Entity.Sup.start_link(@map) # Takes a name for the map
    {:ok, _sup} = Entity.Sup.start_link(@map2)
    # Create a new entity: Choose and ID and attribute set
    {:ok, entity_id} = Entity.start(@map, UUID.uuid1(), %{TestAttr1 => %TestAttr1{}})
    {:ok, [entity: entity_id]}
  end


  test "map change", %{entity: entity_id} do
    assert Entity.exists?(@map, entity_id) == true
    assert Entity.exists?(@map2, entity_id) == false
    Entity.change_area(@map, @map2, entity_id)
    assert Entity.exists?(@map, entity_id) == false
    assert Entity.exists?(@map2, entity_id) == true
  end


  test "attribute adding", %{entity: entity_id} do
    Entity.put_attribute(@map, entity_id, %TestAttr2{})
    assert Entity.has_attribute?(@map, entity_id, TestAttr2) == true
  end


  test "attribute retrieval", %{entity: entity_id} do
    {:ok, %TestAttr1{}} = Entity.get_attribute(@map, entity_id, TestAttr1)
    :error = Entity.get_attribute(@map, entity_id, TestAttr2)

    Entity.put_attribute(@map, entity_id, %TestAttr2{})

    {:ok, %TestAttr1{}} = Entity.get_attribute(@map, entity_id, TestAttr1)
    {:ok, %TestAttr2{}} = Entity.get_attribute(@map, entity_id, TestAttr2)
  end


  test "attribute updateing", %{entity: entity_id} do
    {:ok, %TestAttr1{}} = Entity.get_attribute(@map, entity_id, TestAttr1)
    Entity.update_attribute(@map, entity_id, TestAttr1, fn _ -> %TestAttr1{foo: 42} end)
    {:ok, %TestAttr1{foo: 42}} = Entity.get_attribute(@map, entity_id, TestAttr1)

    :error = Entity.get_attribute(@map, entity_id, TestAttr2)
    Entity.update_attribute(@map, entity_id, TestAttr2, fn _ -> %TestAttr2{baz: true} end)
    :error = Entity.get_attribute(@map, entity_id, TestAttr2)
  end


  test "attribute removal", %{entity: entity_id} do
    assert Entity.has_attribute?(@map, entity_id, TestAttr1) == true
    Entity.remove_attribute(@map, entity_id, TestAttr1)
    assert Entity.has_attribute?(@map, entity_id, TestAttr1) == false
  end
end
