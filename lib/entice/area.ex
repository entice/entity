defmodule Entice.Area do
  use Entice.Area.Maps

  # Lobby is used for temporarily storage of account data and characters
  defmap Lobby

  # Transfer is for entities that undergo a map-change
  defmap Transfer

  defmap HeroesAscent, spawn: %Coord{x: 2017, y: -3241}
  defmap RandomArenas, spawn: %Coord{x: 3854, y: 3874}
  defmap TeamArenas,   spawn: %Coord{x: -1873, y: 352}
end


defmodule Entice.Area.Evt do
  @moduledoc """
  Global event manager for all maps.
  """

  def start_link, do: GenEvent.start_link([name: __MODULE__])

  def entity_added(area, entity_id, attributes) do
    GenEvent.notify(__MODULE__, {:entity_added, area, entity_id, attributes})
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
      worker(Entice.Area.Evt, []) |
      for map <- Entice.Area.get_maps do
        supervisor(Module.concat(map, Sup), [])
      end
    ]

    supervise(children, strategy: :one_for_one)
  end
end
