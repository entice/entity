defmodule Entice.Entity.TriggerTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Trigger
  alias Entice.Entity.Test.Spy

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false


  setup do
    # Create a new entity: Choose an ID and attribute set
    {:ok, _id, pid} = Entity.start(UUID.uuid4(), [%TestAttr1{}])
    Trigger.register(pid)
    Spy.register(pid)
    {:ok, [entity: pid]}
  end


  test "trigger directly after insertion", %{entity: pid} do
    this = self
    Trigger.trigger(pid, fn _ -> send this, :triggered; true end)
    assert_receive :triggered
    Entity.put_attribute(pid, %TestAttr2{})
    refute_receive :triggered
  end


  test "trigger after change", %{entity: pid} do
    this = self
    Trigger.trigger(pid,
      fn %Entity{attributes: %{TestAttr2 => _}} -> send this, :triggered; true
         _ -> false
      end)
    refute_receive :triggered
    Entity.put_attribute(pid, %TestAttr2{})
    assert_receive %{sender: _, event: {:attribute_update, _, _}}
    assert_receive :triggered
    Entity.remove_attribute(pid, TestAttr1)
    refute_receive :triggered
  end
end
