defmodule Entice.Entity.Supervisor do
  alias Entice.Entity
  alias Entice.Utils.ETSSupervisor

  def start_link do
    ETSSupervisor.Sup.start_link(__MODULE__, Entity.Server)
  end
end
