defmodule Entice.EntityTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Test.Spy

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false


  setup do
    # Create a new entity: Choose an ID and attribute set
    {:ok, entity_id, pid} = Entity.start(UUID.uuid4(), [%TestAttr1{}])
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
    assert :ok = Entity.notify(pid, :something)
  end


  test "entity notification w/ id", %{entity_id: entity_id, entity: _pid} do
    assert :ok = Entity.notify(entity_id, :something)
  end


  test "notification of all entities", %{} do
    {:ok, id1, e1} = Entity.start
    {:ok, id2, e2} = Entity.start
    {:ok, id3, e3} = Entity.start
    Spy.register(e1, self)
    Spy.register(e2, self)
    Spy.register(e3, self)

    Entity.notify_all(:test_message)

    assert_receive %{sender: ^id1, event: :test_message}
    assert_receive %{sender: ^id2, event: :test_message}
    assert_receive %{sender: ^id3, event: :test_message}
  end
end
