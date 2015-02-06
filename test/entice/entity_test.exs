defmodule Entice.EntityTest do
  use ExUnit.Case
  alias Entice.Entity

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false


  setup_all do
    {:ok, _sup} = Entity.Supervisor.start_link()
    :ok
  end

  setup do
    # Create a new entity: Choose an ID and attribute set
    {:ok, entity_id} = Entity.start(UUID.uuid4(), %{TestAttr1 => %TestAttr1{}})
    {:ok, [entity: entity_id]}
  end


  test "attribute adding", %{entity: entity_id} do
    Entity.put_attribute(entity_id, %TestAttr2{})
    assert Entity.has_attribute?(entity_id, TestAttr2) == true
  end


  test "attribute retrieval", %{entity: entity_id} do
    {:ok, %TestAttr1{}} = Entity.fetch_attribute(entity_id, TestAttr1)
    assert :error = Entity.fetch_attribute(entity_id, TestAttr2)

    Entity.put_attribute(entity_id, %TestAttr2{})

    assert {:ok, %TestAttr1{}} = Entity.fetch_attribute(entity_id, TestAttr1)
    assert {:ok, %TestAttr2{}} = Entity.fetch_attribute(entity_id, TestAttr2)
  end


  test "attribute updateing", %{entity: entity_id} do
    assert {:ok, %TestAttr1{}} = Entity.fetch_attribute(entity_id, TestAttr1)
    Entity.update_attribute(entity_id, TestAttr1, fn _ -> %TestAttr1{foo: 42} end)
    assert {:ok, %TestAttr1{foo: 42}} = Entity.fetch_attribute(entity_id, TestAttr1)

    assert :error = Entity.fetch_attribute(entity_id, TestAttr2)
    Entity.update_attribute(entity_id, TestAttr2, fn _ -> %TestAttr2{baz: true} end)
    assert :error = Entity.fetch_attribute(entity_id, TestAttr2)
  end


  test "attribute removal", %{entity: entity_id} do
    assert Entity.has_attribute?(entity_id, TestAttr1) == true
    Entity.remove_attribute(entity_id, TestAttr1)
    assert Entity.has_attribute?(entity_id, TestAttr1) == false
  end
end
