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
    {:ok, entity_id, pid} = Entity.start(UUID.uuid4(), %{TestAttr1 => %TestAttr1{}})
    {:ok, [entity_id: entity_id, entity: pid]}
  end


  test "entity retrieval", %{entity_id: entity_id, entity: pid} do
    assert {:ok, ^pid} = Entity.fetch(entity_id)
    assert {:error, _} = Entity.fetch("no-id")
  end


  test "entity termination", %{entity_id: entity_id, entity: pid} do
    {:ok, id1, pid1} = Entity.start(UUID.uuid4(), %{TestAttr1 => %TestAttr1{}})
    assert {:ok, ^pid1} = Entity.fetch(id1)
    Entity.stop(id1)
    assert {:error, _} = Entity.fetch(id1)
  end


  test "attribute adding", %{entity_id: _entity_id, entity: pid} do
    Entity.put_attribute(pid, %TestAttr2{})
    assert Entity.has_attribute?(pid, TestAttr2) == true
  end


  test "attribute retrieval", %{entity_id: _entity_id, entity: pid} do
    {:ok, %TestAttr1{}} = Entity.fetch_attribute(pid, TestAttr1)
    assert :error = Entity.fetch_attribute(pid, TestAttr2)

    Entity.put_attribute(pid, %TestAttr2{})

    assert {:ok, %TestAttr1{}} = Entity.fetch_attribute(pid, TestAttr1)
    assert {:ok, %TestAttr2{}} = Entity.fetch_attribute(pid, TestAttr2)
  end


  test "attribute updateing", %{entity_id: _entity_id, entity: pid} do
    assert {:ok, %TestAttr1{}} = Entity.fetch_attribute(pid, TestAttr1)
    Entity.update_attribute(pid, TestAttr1, fn _ -> %TestAttr1{foo: 42} end)
    assert {:ok, %TestAttr1{foo: 42}} = Entity.fetch_attribute(pid, TestAttr1)

    assert :error = Entity.fetch_attribute(pid, TestAttr2)
    Entity.update_attribute(pid, TestAttr2, fn _ -> %TestAttr2{baz: true} end)
    assert :error = Entity.fetch_attribute(pid, TestAttr2)
  end


  test "attribute removal", %{entity_id: _entity_id, entity: pid} do
    assert Entity.has_attribute?(pid, TestAttr1) == true
    Entity.remove_attribute(pid, TestAttr1)
    assert Entity.has_attribute?(pid, TestAttr1) == false
  end
end
