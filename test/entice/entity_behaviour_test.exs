defmodule Entice.Entity.BehaviourTest do
  use ExUnit.Case
  alias Entice.Entity
  alias Entice.Entity.Behaviour

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false


  defmodule TestBehaviour do
    use Behaviour
    alias Entice.Entity.BehaviourTest.TestAttr1


    def init(attrs, test_pid),
    do: {:ok, Map.put(attrs, TestAttr1, %TestAttr1{}), {:some_state, test_pid}}


    def handle_event({:bar, _event}, %{TestAttr1 => _} = attributes, {:some_state, test_pid} = state) do
      send(test_pid, {:got, :bar})
      {:ok, attributes, state}
    end


    def handle_event({:add, %{__struct__: attr_type} = attr}, %{TestAttr1 => _} = attributes, {:some_state, test_pid} = state) do
      send(test_pid, {:got, :add})
      {:ok, Map.put(attributes, attr_type, attr), state}
    end


    def terminate(reason, attributes, {:some_state, test_pid}) do
      send(test_pid, {:got, :terminate, reason})
      {:ok, Map.delete(attributes, TestAttr1)}
    end
  end


  setup do
    # Create a new entity: Choose an ID and attribute set
    {:ok, _id, pid} = Entity.start
    {:ok, [entity: pid]}
  end


  test "behaviour adding & event reaction", %{entity: pid} do
    Entity.put_behaviour(pid, TestBehaviour, self)
    assert Entity.has_attribute?(pid, TestAttr1) == true

    # send normal event
    send(pid, {:bar, :some_event})
    assert_receive {:got, :bar}

    # send unhandled event (no behaviour handles it)
    send(pid, {:nop, :nothing})
    refute_receive {:got, :nop}

    # send normal event, entity should still behave the same
    send(pid, {:bar, :some_event})
    assert_receive {:got, :bar}
  end


  test "entity state manipulation from behaviour", %{entity: pid} do
    Entity.put_behaviour(pid, TestBehaviour, self)

    # send normal event
    send(pid, {:add, %TestAttr2{}})
    assert_receive {:got, :add}

    assert Entity.has_attribute?(pid, TestAttr2) == true
  end


  test "behaviour removal", %{entity: pid} do
    Entity.put_behaviour(pid, TestBehaviour, self)

    # send normal event
    send(pid, {:bar, :existence_check})
    assert_receive {:got, :bar}

    Entity.remove_behaviour(pid, TestBehaviour)
    assert_receive {:got, :terminate, :remove_handler}

    assert Entity.has_attribute?(pid, TestAttr1) == false

    # send normal event, now shouldnt respond
    send(pid, {:bar, :existence_check})
    refute_receive {:got, :bar}
  end
end
