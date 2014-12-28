defmodule Entice.Cynosure.Entity.Supervisor do
  @moduledoc """
  Simple entity supervisor that does not restart entities when they despawn.
  """
  use Supervisor

  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, :ok, opts)

  def start_entity(supervisor, id, event_manager, opts) do
    Supervisor.start_child(supervisor, [id, event_manager, opts])
  end

  def init(:ok) do
    children = [
      worker(Entice.Cynosure.Entity, [], restart: :temporary)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
