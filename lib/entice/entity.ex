defmodule Entice.Entity do
  alias GenServer
  alias Entice.Utils.ETSSupervisor


  defstruct(
    id: "",
    attributes: %{})


  def start(entity_id, attributes \\ %{}, opts \\ []) do
    ETSSupervisor.start(__MODULE__.Supervisor, entity_id, [attributes | opts])
    {:ok, entity_id}
  end


  def stop(entity_id),
  do: ETSSupervisor.terminate(__MODULE__.Supervisor, entity_id)


  def exists?(entity_id) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, _} -> true
      _        -> false
    end
  end


  def has_attribute?(entity_id, attribute_type) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, e} -> GenServer.call(e, {:has_attribute, attribute_type})
      err      -> err
    end
  end


  def fetch_attribute(entity_id, attribute_type) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, e} -> GenServer.call(e, {:fetch_attribute, attribute_type})
      err      -> err
    end
  end


  def put_attribute(entity_id, attribute) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, e} -> GenServer.cast(e, {:put_attribute, attribute})
      err      -> err
    end
  end


  def update_attribute(entity_id, attribute_type, modifier) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, e} -> GenServer.cast(e, {:update_attribute, attribute_type, modifier})
      err      -> err
    end
  end


  def remove_attribute(entity_id, attribute_type) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, e} -> GenServer.cast(e, {:remove_attribute, attribute_type})
      err      -> err
    end
  end
end
