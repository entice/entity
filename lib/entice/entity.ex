defmodule Entice.Entity do
  alias GenServer
  alias Entice.Utils.ETSSupervisor


  defstruct(
    id: "",
    attributes: %{})


  # Entity lifecycle & retrieval API


  def start, do: start(UUID.uuid4())

  def start(entity_id, attributes \\ %{}, opts \\ []) do
    {:ok, pid} = ETSSupervisor.start(__MODULE__.Supervisor, entity_id, [attributes | opts])
    {:ok, entity_id, pid}
  end


  def stop(entity_id),
  do: ETSSupervisor.terminate(__MODULE__.Supervisor, entity_id)


  def exists?(entity_id) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, _} -> true
      _        -> false
    end
  end


  def fetch(entity_id),
  do: ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id)


  # Entity internal API


  def has_attribute?(entity, attribute_type),
  do: GenServer.call(entity, {:has_attribute, attribute_type})


  def fetch_attribute(entity, attribute_type),
  do: GenServer.call(entity, {:fetch_attribute, attribute_type})


  def put_attribute(entity, attribute),
  do: GenServer.cast(entity, {:put_attribute, attribute})


  def update_attribute(entity, attribute_type, modifier),
  do: GenServer.cast(entity, {:update_attribute, attribute_type, modifier})


  def remove_attribute(entity, attribute_type),
  do: GenServer.cast(entity, {:remove_attribute, attribute_type})
end
