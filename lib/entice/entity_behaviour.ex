defmodule Entice.Entity.Behaviour do
  @moduledoc """
  A behaviour is generic event handler that can be injected into an entity.
  This handler can then act when the entity receives notifications, and
  can manipulate the entities state. (SyncEvent handler wrapper currently)
  """

  defmacro __using__(_) do
    quote do
      use Entice.Utils.SyncEvent
      alias Entice.Entity
    end
  end
end
