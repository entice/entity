defmodule Entice.Logic.AttributeNotifyTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.AttributeNotify
  alias Entice.Entity.Test.Spy

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
    AttributeNotify.add_listener(eid, self, false)
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


  test "should remove the listener when it dies", %{entity_id: eid} do
    Spy.register(eid)
    this = self

    proc = spawn(fn ->
      receive do
        {:attribute_notification, _msg} ->
          send this, :got_notification
          :ok
      end
    end)
    AttributeNotify.add_listener(eid, proc, false)

    assert {:ok, %AttributeNotify{listeners: [^proc, ^this]}} = Entity.fetch_attribute(eid, AttributeNotify)

    Entity.remove_attribute(eid, TestAttr2)

    assert_receive :got_notification
    assert_receive %{sender: ^eid, event: {:DOWN, _, _, ^proc, _}}
    assert {:ok, %AttributeNotify{listeners: [^this]}} = Entity.fetch_attribute(eid, AttributeNotify)
  end


  test "Should not report changes to its own attribute", %{entity_id: eid} do
    assert_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}},
      changed: %{},
      removed: []}}

    proc = spawn_link(fn ->
      receive do
        :not_gonna_happen -> :ok
      end
    end)
    AttributeNotify.add_listener(eid, proc, false)

    refute_receive {:attribute_notification, %{
      entity_id: ^eid,
      added: %{},
      changed: %{AttributeNotify => %AttributeNotify{}},
      removed: []}}
  end
end
