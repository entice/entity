defmodule Entice.EntityTest do
  use ExUnit.Case, async: true
  alias Entice.Entity


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
end
