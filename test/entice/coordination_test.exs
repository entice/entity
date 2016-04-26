defmodule Entice.Logic.CoordinationTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.{Coordination, Test.Spy}

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false
  defmodule TestAttr3, do: defstruct crux: "hello"


  setup do
    {:ok, eid, _pid} = Entity.start
    eid |> Coordination.register(__MODULE__)

    Entity.put_attribute(eid, %TestAttr1{})
    Entity.put_attribute(eid, %TestAttr2{})

    Coordination.register_observer(self, __MODULE__)

    {:ok, [entity_id: eid]}
  end


  test "entity notification", %{entity_id: eid} do
    Spy.register(eid, self)
    assert :ok = Coordination.notify(eid, :something)
    assert_receive %{sender: ^eid, event: :something}
  end


  test "notification of all entities" do
    {:ok, id1, e1} = Entity.start
    {:ok, id2, e2} = Entity.start
    {:ok, id3, e3} = Entity.start
    Coordination.register(e1, __MODULE__)
    Coordination.register(e2, __MODULE__)
    Coordination.register(e3, __MODULE__)
    Spy.register(e1, self)
    Spy.register(e2, self)
    Spy.register(e3, self)

    Coordination.notify_all(__MODULE__, :test_message)

    assert_receive %{sender: ^id1, event: :test_message}
    assert_receive %{sender: ^id2, event: :test_message}
    assert_receive %{sender: ^id3, event: :test_message}
  end


  test "notification of all entities local to an entity", %{entity_id: eid} do
    {:ok, id1, e1} = Entity.start
    {:ok, id2, e2} = Entity.start
    {:ok, id3, e3} = Entity.start
    Coordination.register(e1, __MODULE__)
    Coordination.register(e2, __MODULE__)
    Coordination.register(e3, __MODULE__)
    Spy.register(e1, self)
    Spy.register(e2, self)
    Spy.register(e3, self)

    Coordination.notify_locally(eid, :test_message)

    assert_receive %{sender: ^id1, event: :test_message}
    assert_receive %{sender: ^id2, event: :test_message}
    assert_receive %{sender: ^id3, event: :test_message}
  end


  test "observer registry", %{entity_id: eid} do
    assert_receive {:entity_join, %{
      entity_id: ^eid,
      attributes: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}}}}
  end


  test "add attributes", %{entity_id: eid} do
    Entity.put_attribute(eid, %TestAttr3{})
    assert_receive {:entity_change, %{
      entity_id: ^eid,
      added: %{TestAttr3 => %TestAttr3{}},
      changed: %{},
      removed: %{}}}
  end


  test "change attributes", %{entity_id: eid} do
    Entity.put_attribute(eid, %TestAttr1{foo: 42})
    assert_receive {:entity_change, %{
      entity_id: ^eid,
      added: %{},
      changed: %{TestAttr1 => %TestAttr1{foo: 42}},
      removed: %{}}}
  end


  test "delete attributes", %{entity_id: eid} do
    Entity.remove_attribute(eid, TestAttr1)
    assert_receive {:entity_change, %{
      entity_id: ^eid,
      added: %{},
      changed: %{},
      removed: %{TestAttr1 => %TestAttr1{}}}}
  end


  test "entity join" do
    {:ok, eid2, _pid} = Entity.start_plain()
    Coordination.register(eid2, __MODULE__)
    assert_receive {:entity_join, %{
      entity_id: ^eid2,
      attributes: %{}}}
  end


  test "entity leave", %{entity_id: eid} do
    Entity.stop(eid)
    assert_receive {:entity_leave, %{
      entity_id: ^eid,
      attributes: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}}}}
  end


  test "gracefully stopping of channels" do
    assert :ok = Coordination.stop_channel(__MODULE__)
    assert :ok = Coordination.stop_channel(:non_existing_channel)
    assert :error = Coordination.notify_all(:non_existing_channel, :blubb)
  end
end
