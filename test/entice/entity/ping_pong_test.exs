defmodule Entice.Entity.PingPongTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.PingPong


  setup do
    {:ok, eid, _pid} = Entity.start_plain()
    PingPong.register(eid)
    {:ok, %{entity: eid}}
  end


  test "kill an entity via poison pill", %{entity: eid} do
    assert :pong = PingPong.ping(eid)
  end
end
