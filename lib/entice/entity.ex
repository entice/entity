defmodule Entice.Entity do
  @moduledoc """
  Thin convenience wrapper around a `Entice.Utils.SyncEvent` manager.
  """
  alias Entice.Entity
  alias Entice.Entity.Attribute
  alias Entice.Utils.ETSSupervisor
  alias Entice.Utils.SyncEvent


  defstruct(
    id: "",
    attributes: %{})


  # Entity lifecycle & retrieval API


  def start, do: start(UUID.uuid4())
  def start(entity_id), do: start(entity_id, %{})

  def start(entity_id, attributes) when is_list(attributes) do
    start(entity_id, attributes |> Enum.into(%{}, fn x -> {x.__struct__, x} end))
  end

  @doc "Starts a new entity with attached attribute management behaviour"
  def start(entity_id, attributes) when is_map(attributes) do
    {:ok, pid} = ETSSupervisor.start(__MODULE__.Supervisor, entity_id, [%Entity{id: entity_id, attributes: attributes}])
    pid |> Attribute.register
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


  def notify(entity, message) when is_pid(entity), do: SyncEvent.notify(entity, message)
  def notify(entity_id, message), do: entity_id |> lookup_and_do(&notify(&1, message))


  def call(entity, behaviour, message) when is_pid(entity), do: SyncEvent.call(entity, behaviour, message)
  def call(entity_id, behaviour, message), do: entity_id |> lookup_and_do(&call(&1, behaviour, message))


  # Attribute API (delegates to attribute-management behaviour)


  def has_attribute?(entity, attribute_type), do: Attribute.has?(entity, attribute_type)


  def fetch_attribute(entity, attribute_type), do: Attribute.fetch(entity, attribute_type)


  def fetch_attribute!(entity, attribute_type), do: Attribute.fetch!(entity, attribute_type)


  def get_and_update(entity, attribute_type, modifier), do: Attribute.get_and_update(entity, attribute_type, modifier)


  def put_attribute(entity, attribute), do: Attribute.put(entity, attribute)


  def update_attribute(entity, attribute_type, modifier), do: Attribute.update(entity, attribute_type, modifier)


  def remove_attribute(entity, attribute_type), do: Attribute.remove(entity, attribute_type)


  # Behaviour API


  def has_behaviour?(entity, behaviour) when is_pid(entity) and is_atom(behaviour),
  do: SyncEvent.has_handler?(entity, behaviour)

  def has_behaviour?(entity_id, behaviour), do: entity_id |> lookup_and_do(&has_behaviour?(&1, behaviour))


  def put_behaviour(entity, behaviour, args) when is_pid(entity) and is_atom(behaviour),
  do: SyncEvent.put_handler(entity, behaviour, args)

  def put_behaviour(entity_id, behaviour, args), do: entity_id |> lookup_and_do(&put_behaviour(&1, behaviour, args))


  def remove_behaviour(entity, behaviour) when is_pid(entity) and is_atom(behaviour),
  do: SyncEvent.remove_handler(entity, behaviour)

  def remove_behaviour(entity_id, behaviour), do: entity_id |> lookup_and_do(&remove_behaviour(&1, behaviour))


  # Internal

  defp lookup_and_do(entity_id, fun) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, e} -> fun.(e)
      _        -> :error
    end
  end
end


defmodule Entice.Entity.Server do
  alias Entice.Entity
  alias Entice.Utils.SyncEvent

  def start_link(args),
  do: SyncEvent.start_link(args)
end


defmodule Entice.Entity.Supervisor do
  alias Entice.Entity
  alias Entice.Utils.ETSSupervisor

  def start_link,
  do: ETSSupervisor.Supervisor.start_link(__MODULE__, Entity.Server)
end
