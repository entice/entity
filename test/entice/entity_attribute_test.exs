defmodule Entice.Entity.AttributeTest do
  use ExUnit.Case
  alias Entice.Entity
  alias Entice.Entity.Attribute

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false


  setup do
    # Create a new entity: Choose an ID and attribute set
    {:ok, _id, pid} = Entity.start(UUID.uuid4(), [%TestAttr1{}])
    Attribute.start(pid)
    {:ok, [entity: pid]}
  end


  test "attribute adding", %{entity: pid} do
    Attribute.put(pid, %TestAttr2{})
    assert Attribute.has?(pid, TestAttr2) == true
  end


  test "attribute retrieval", %{entity: pid} do
    {:ok, %TestAttr1{}} = Attribute.fetch(pid, TestAttr1)
    assert :error = Attribute.fetch(pid, TestAttr2)

    Attribute.put(pid, %TestAttr2{})

    assert {:ok, %TestAttr1{}} = Attribute.fetch(pid, TestAttr1)
    assert {:ok, %TestAttr2{}} = Attribute.fetch(pid, TestAttr2)
  end


  test "attribute retrieval w/ raise", %{entity: pid} do
    %TestAttr1{} = Attribute.fetch!(pid, TestAttr1)
    assert_raise KeyError, fn -> Attribute.fetch!(pid, TestAttr2) end
  end


  test "attribute updating", %{entity: pid} do
    assert {:ok, %TestAttr1{}} = Attribute.fetch(pid, TestAttr1)
    Attribute.update(pid, TestAttr1, fn _ -> %TestAttr1{foo: 42} end)
    assert {:ok, %TestAttr1{foo: 42}} = Attribute.fetch(pid, TestAttr1)

    assert :error = Attribute.fetch(pid, TestAttr2)
    Attribute.update(pid, TestAttr2, fn _ -> %TestAttr2{baz: true} end)
    assert :error = Attribute.fetch(pid, TestAttr2)
  end


  test "attribute removal", %{entity: pid} do
    assert Attribute.has?(pid, TestAttr1) == true
    Attribute.remove(pid, TestAttr1)
    assert Attribute.has?(pid, TestAttr1) == false
  end
end
