defmodule Entice.Entity.AttributeTest do
  use ExUnit.Case
  alias Entice.Entity
  alias Entice.Entity.Attribute

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false


  setup do
    # Create a new entity: Choose an ID and attribute set
    {:ok, _id, pid} = Entity.start(UUID.uuid4(), [%TestAttr1{}])
    {:ok, [entity: pid]}
  end


  test "attribute adding", %{entity: pid} do
    Attribute.put(pid, %TestAttr2{})
    assert Attribute.has?(pid, TestAttr2) == true
  end


  test "attribute fetching", %{entity: pid} do
    {:ok, %TestAttr1{}} = Attribute.fetch(pid, TestAttr1)
    assert :error = Attribute.fetch(pid, TestAttr2)

    Attribute.put(pid, %TestAttr2{})

    assert {:ok, %TestAttr1{}} = Attribute.fetch(pid, TestAttr1)
    assert {:ok, %TestAttr2{}} = Attribute.fetch(pid, TestAttr2)
  end


  test "attribute getting", %{entity: pid} do
    %TestAttr1{} = Attribute.get(pid, TestAttr1)
    assert nil = Attribute.get(pid, TestAttr2)

    Attribute.put(pid, %TestAttr2{})

    assert %TestAttr1{} = Attribute.get(pid, TestAttr1)
    assert %TestAttr2{} = Attribute.get(pid, TestAttr2)
  end


  test "attribute fetching w/ raise", %{entity: pid} do
    %TestAttr1{} = Attribute.fetch!(pid, TestAttr1)
    assert_raise KeyError, fn -> Attribute.fetch!(pid, TestAttr2) end
  end


  test "attribute get & update", %{entity: pid} do
    assert {:ok, %TestAttr1{}} = Attribute.fetch(pid, TestAttr1)
    assert %TestAttr1{foo: 42} = Attribute.get_and_update(pid, TestAttr1, fn _ -> %TestAttr1{foo: 42} end)

    assert :error = Attribute.fetch(pid, TestAttr2)
    assert nil = Attribute.get_and_update(pid, TestAttr2, fn _ -> %TestAttr2{baz: true} end)
    assert :error = Attribute.fetch(pid, TestAttr2)
  end


  test "attribute take", %{entity: pid} do
    assert %{TestAttr1 => %TestAttr1{}} = Attribute.take(pid, [TestAttr1, TestAttr2])
    Attribute.put(pid, %TestAttr2{})
    assert %{TestAttr1 => %TestAttr1{}, TestAttr2 => %TestAttr2{}} = 
      Attribute.take(pid, [TestAttr1, TestAttr2])
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


  test "attribute transaction", %{entity: pid} do
    assert Attribute.has?(pid, TestAttr1) == true
    Attribute.transaction(pid, fn attrs ->
      attrs
      |> Map.delete(TestAttr1)
      |> Map.put(TestAttr2, %TestAttr2{})
    end)
    assert Attribute.has?(pid, TestAttr1) == false
    assert Attribute.has?(pid, TestAttr2) == true
  end
end
