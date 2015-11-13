defmodule Entice.Entity.SuicideTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Suicide
  alias Entice.Entity.Test.Spy


  setup do
    {:ok, eid, _pid} = Entity.start_plain()
    Suicide.register(eid)
    Spy.register(eid)
    {:ok, %{entity: eid}}
  end


  test "kill an entity via poison pill", %{entity: eid} do
    Suicide.poison_pill(eid)
    assert_receive %{sender: ^eid, event: {:entity_terminate, :normal}}
  end
end
