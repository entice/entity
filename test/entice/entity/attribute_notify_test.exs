defmodule Entice.Logic.AttributeNotifyTest do
  use ExUnit.Case
  alias Entice.Entity
  alias Entice.Entity.AttributeNotify

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false
  defmodule TestAttr3, do: defstruct crux: "hello"


  setup do
    {:ok, eid, _pid} = Entity.start

    Entity.put_attribute(eid, %TestAttr1{})
    Entity.put_attribute(eid, %TestAttr2{})
    AttributeNotify.add_listener(eid, self)

    {:ok, [entity_id: eid]}
  end


  test "register listener", %{entity_id: eid} do
    assert_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}},
      changed: %{},
      removed: []}}
  end


  test "unregister listener", %{entity_id: eid} do
    assert_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}},
      changed: %{},
      removed: []}}
    AttributeNotify.remove_listener(eid, self)
    Entity.put_attribute(eid, %TestAttr1{foo: 42})
    refute_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{},
      changed: %{TestAttr1 => %TestAttr1{foo: 42}},
      removed: []}}
  end


  test "register listener w/o initial attribute report", %{entity_id: eid} do
    assert_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}},
      changed: %{},
      removed: []}}
    AttributeNotify.remove_listener(eid, self)
    AttributeNotify.add_listener(eid, self, initial_report = false)
    refute_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}},
      changed: %{},
      removed: []}}
  end


  test "change attributes", %{entity_id: eid} do
    Entity.put_attribute(eid, %TestAttr1{foo: 42})
    assert_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{},
      changed: %{TestAttr1 => %TestAttr1{foo: 42}},
      removed: []}}
  end


  test "add attributes", %{entity_id: eid} do
    Entity.put_attribute(eid, %TestAttr3{})
    assert_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{TestAttr3 => %TestAttr3{}},
      changed: %{},
      removed: []}}
  end


  test "remove attributes", %{entity_id: eid} do
    Entity.remove_attribute(eid, TestAttr2)
    assert_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{},
      changed: %{},
      removed: [TestAttr2]}}
  end


  test "all stuff at the same time", %{entity_id: eid} do
    Entity.attribute_transaction(eid, fn attrs ->
      attrs
      |> Map.put(TestAttr1, %TestAttr1{foo: 42})
      |> Map.put(TestAttr3, %TestAttr3{})
      |> Map.delete(TestAttr2)
    end)
    assert_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{TestAttr3 => %TestAttr3{}},
      changed: %{TestAttr1 => %TestAttr1{foo: 42}},
      removed: [TestAttr2]}}
  end
end
