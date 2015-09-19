defmodule Entice.Entity.DiscoveryTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Discovery
  alias Entice.Entity.Test.Spy

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false


  setup do
    # Create a new entity: Choose an ID and attribute set
    {:ok, id1, pid} = Entity.start(UUID.uuid4(), [%TestAttr1{}])
    {:ok, id2, _pid} = Entity.start(UUID.uuid4(), [%TestAttr1{}])
    Spy.register(pid)
    {:ok, [id1: id1, id2: id2, entity: pid]}
  end


  test "discovery of an existing attribute", %{id1: id1, id2: id2, entity: pid} do
    Discovery.discover_attribute(TestAttr1, self)
    assert_receive {:discovered, %Entity{id: ^id1}}
    assert_receive {:discovered, %Entity{id: ^id2}}
    Entity.put_attribute(pid, %TestAttr2{})
    refute_receive {:discovered, %Entity{id: ^id1}}
  end


  test "discovery of a later-on added attribute", %{id1: id, entity: pid} do
    Discovery.discover_attribute(TestAttr2, self)
    refute_receive {:discovered, %Entity{id: ^id}}
    Entity.put_attribute(pid, %TestAttr2{})
    assert_receive {:discovered, %Entity{id: ^id}}
  end


  test "undiscovery of an attribute", %{id1: id, entity: pid} do
    Discovery.undiscover_attribute(pid, TestAttr1, self)
    refute_receive {:undiscovered, %Entity{id: ^id}}
    Entity.remove_attribute(pid, TestAttr1)
    assert_receive {:undiscovered, %Entity{id: ^id}}
  end
end
