defmodule Entice.Area do
  use Entice.Area.Maps

  # Lobby is used for temporarily storage of account data and characters
  defmap Lobby

  defmap HeroesAscent
  defmap RandomArenas
  defmap TeamArenas
end


defmodule Entice.Area.Evt do
  @moduledoc """
  Global event manager for all maps.
  """

  def start_link, do: GenEvent.start_link([name: __MODULE__])

  def entity_added(area, entity_id) do
    GenEvent.notify(__MODULE__, {:entity_added, area, entity_id})
  end

  def entity_removed(area, entity_id) do
    GenEvent.notify(__MODULE__, {:entity_removed, area, entity_id})
  end

  def attribute_updated(area, entity_id, attribute) do
    GenEvent.notify(__MODULE__, {:attribute_updated, area, entity_id, attribute})
  end

  def attribute_removed(area, entity_id, attribute_type) do
    GenEvent.notify(__MODULE__, {:attribute_removed, area, entity_id, attribute_type})
  end
end


defmodule Entice.Area.Sup do
  @moduledoc """
  Supervisor for all map supervisors
  """
  use Supervisor

  def start_link, do: Supervisor.start_link(__MODULE__, :ok)

  def init(:ok) do
    children = [
      worker(Entice.Area.Evt, []),
      supervisor(Entice.Area.HeroesAscent.Sup, []),
      supervisor(Entice.Area.RandomArenas.Sup, []),
      supervisor(Entice.Area.TeamArenas.Sup, [])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
