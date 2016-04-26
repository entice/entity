defmodule Entice.Entity.PingPong do
  @moduledoc """
  A synchronous ping/pong check if the entity is still
  capable of receiving and sending. Can be used in tests
  when waiting for some entity-internal state change.
  """
  alias Entice.Entity
  alias Entice.Entity.PingPong


  def register(entity),
  do: Entity.put_behaviour(entity, PingPong.Behaviour, [])


  def unregister(entity),
  do: Entity.remove_behaviour(entity, PingPong.Behaviour)


  @doc "Only expected reply is: :pong"
  def ping(entity), do: Entity.call_behaviour(entity, PingPong.Behaviour, :ping_pong_ping)


  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def handle_call(:ping_pong_ping, entity),
    do: {:ok, :pong, entity}
  end
end
