defmodule Entice.Cynosure.EntityTest do
  use ExUnit.Case
  alias Entice.Cynosure.Entity

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false

  setup do
    {:ok, entity} = Entity.start_link("", self(), [attributes: %{TestAttr1 => %TestAttr1{}}])
    {:ok, [entity: entity]}
  end


  test "attribute adding", %{entity: entity} do
    Entity.put_attribute(entity, %TestAttr2{})
    assert Entity.has_attribute?(entity, %TestAttr2{}) == true
    assert Entity.has_attribute?(entity, TestAttr2) == true
  end


  test "attribute retrieval", %{entity: entity} do
    {:ok, %TestAttr1{}} = Entity.get_attribute(entity, %TestAttr1{})
    :error = Entity.get_attribute(entity, %TestAttr2{})

    Entity.put_attribute(entity, %TestAttr2{})

    {:ok, %TestAttr1{}} = Entity.get_attribute(entity, TestAttr1)
    {:ok, %TestAttr2{}} = Entity.get_attribute(entity, TestAttr2)
  end


  test "attribute updateing", %{entity: entity} do
    {:ok, %TestAttr1{}} = Entity.get_attribute(entity, %TestAttr1{})
    Entity.update_attribute(entity, TestAttr1, fn _ -> %TestAttr1{foo: 42} end)
    {:ok, %TestAttr1{foo: 42}} = Entity.get_attribute(entity, TestAttr1)

    :error = Entity.get_attribute(entity, %TestAttr2{})
    Entity.update_attribute(entity, TestAttr2, fn _ -> %TestAttr2{baz: true} end)
    :error = Entity.get_attribute(entity, TestAttr2)
  end


  test "attribute removal", %{entity: entity} do
    assert Entity.has_attribute?(entity, TestAttr1) == true
    Entity.remove_attribute(entity, TestAttr1)
    assert Entity.has_attribute?(entity, TestAttr1) == false
  end
end
