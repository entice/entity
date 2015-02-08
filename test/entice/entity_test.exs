defmodule Entice.EntityTest do
  use ExUnit.Case
  alias Entice.Entity

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false


  setup do
    # Create a new entity: Choose an ID and attribute set
    {:ok, entity_id, pid} = Entity.start(UUID.uuid4(), %{TestAttr1 => %TestAttr1{}})
    {:ok, [entity_id: entity_id, entity: pid]}
  end


  test "entity retrieval", %{entity_id: entity_id, entity: pid} do
    assert {:ok, ^pid} = Entity.fetch(entity_id)
    assert {:error, _} = Entity.fetch("no-id")
  end


  test "entity termination", %{entity_id: _entity_id, entity: _pid} do
    {:ok, id1, pid1} = Entity.start(UUID.uuid4(), %{TestAttr1 => %TestAttr1{}})
    assert {:ok, ^pid1} = Entity.fetch(id1)
    Entity.stop(id1)
    assert {:error, _} = Entity.fetch(id1)
  end


  test "entity notification", %{entity_id: _entity_id, entity: pid} do
    assert :something = Entity.notify(pid, :something)
  end


  test "entity notification w/ id", %{entity_id: entity_id, entity: _pid} do
    assert :something = Entity.notify(entity_id, :something)
  end


  test "attribute adding", %{entity_id: _entity_id, entity: pid} do
    Entity.put_attribute(pid, %TestAttr2{})
    assert Entity.has_attribute?(pid, TestAttr2) == true
  end


  test "attribute adding w/ id", %{entity_id: entity_id, entity: _pid} do
    Entity.put_attribute(entity_id, %TestAttr2{})
    assert Entity.has_attribute?(entity_id, TestAttr2) == true
  end


  test "attribute retrieval", %{entity_id: _entity_id, entity: pid} do
    {:ok, %TestAttr1{}} = Entity.fetch_attribute(pid, TestAttr1)
    assert :error = Entity.fetch_attribute(pid, TestAttr2)

    Entity.put_attribute(pid, %TestAttr2{})

    assert {:ok, %TestAttr1{}} = Entity.fetch_attribute(pid, TestAttr1)
    assert {:ok, %TestAttr2{}} = Entity.fetch_attribute(pid, TestAttr2)
  end


  test "attribute retrieval w/ id", %{entity_id: entity_id, entity: _pid} do
    {:ok, %TestAttr1{}} = Entity.fetch_attribute(entity_id, TestAttr1)
    assert :error = Entity.fetch_attribute(entity_id, TestAttr2)

    Entity.put_attribute(entity_id, %TestAttr2{})

    assert {:ok, %TestAttr1{}} = Entity.fetch_attribute(entity_id, TestAttr1)
    assert {:ok, %TestAttr2{}} = Entity.fetch_attribute(entity_id, TestAttr2)
  end


  test "attribute updating", %{entity_id: _entity_id, entity: pid} do
    assert {:ok, %TestAttr1{}} = Entity.fetch_attribute(pid, TestAttr1)
    Entity.update_attribute(pid, TestAttr1, fn _ -> %TestAttr1{foo: 42} end)
    assert {:ok, %TestAttr1{foo: 42}} = Entity.fetch_attribute(pid, TestAttr1)

    assert :error = Entity.fetch_attribute(pid, TestAttr2)
    Entity.update_attribute(pid, TestAttr2, fn _ -> %TestAttr2{baz: true} end)
    assert :error = Entity.fetch_attribute(pid, TestAttr2)
  end


  test "attribute updating w/ id", %{entity_id: entity_id, entity: _pid} do
    assert {:ok, %TestAttr1{}} = Entity.fetch_attribute(entity_id, TestAttr1)
    Entity.update_attribute(entity_id, TestAttr1, fn _ -> %TestAttr1{foo: 42} end)
    assert {:ok, %TestAttr1{foo: 42}} = Entity.fetch_attribute(entity_id, TestAttr1)

    assert :error = Entity.fetch_attribute(entity_id, TestAttr2)
    Entity.update_attribute(entity_id, TestAttr2, fn _ -> %TestAttr2{baz: true} end)
    assert :error = Entity.fetch_attribute(entity_id, TestAttr2)
  end


  test "attribute removal", %{entity_id: _entity_id, entity: pid} do
    assert Entity.has_attribute?(pid, TestAttr1) == true
    Entity.remove_attribute(pid, TestAttr1)
    assert Entity.has_attribute?(pid, TestAttr1) == false
  end


  test "attribute removal w/ id", %{entity_id: entity_id, entity: _pid} do
    assert Entity.has_attribute?(entity_id, TestAttr1) == true
    Entity.remove_attribute(entity_id, TestAttr1)
    assert Entity.has_attribute?(entity_id, TestAttr1) == false
  end
end
