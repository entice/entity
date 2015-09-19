defmodule Entice.Logic.CoordinationTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Entity.Test.Spy

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false
  defmodule TestAttr3, do: defstruct crux: "hello"


  setup do
    {:ok, eid, _pid} = Entity.start

    Entity.put_attribute(eid, %TestAttr1{})
    Entity.put_attribute(eid, %TestAttr2{})
    Coordination.start()
    Coordination.register_entity(eid)

    {:ok, [entity_id: eid]}
  end


  test "observer registry", %{entity_id: eid} do
    Coordination.register_observer(self())
    assert_receive {:entity_join, %{
      entity_id: ^eid,
      attributes: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}}}}
  end
end
