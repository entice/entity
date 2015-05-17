defmodule Entice.Entity do
  @moduledoc """
  Thin convenience wrapper around a `Entice.Utils.SyncEvent` manager.
  """
  alias Entice.Utils.ETSSupervisor
  alias Entice.Utils.SyncEvent
  alias Entice.Entity
  alias Entice.Entity.Attribute
  alias Entice.Entity.AttributeNotify
  alias Entice.Entity.Trigger


  defstruct id: "", attributes: %{}


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
    pid |> AttributeNotify.register
    pid |> Trigger.register
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


  def call(entity, behaviour, message) when is_pid(entity), do: SyncEvent.call(entity, behaviour, message)
  def call(entity_id, behaviour, message), do: entity_id |> lookup_and_do(&call(&1, behaviour, message))


  def notify(entity, message) when is_pid(entity), do: SyncEvent.notify(entity, message)
  def notify(entity_id, message), do: entity_id |> lookup_and_do(&notify(&1, message))


  def notify_all(message) do
    ETSSupervisor.get_all(__MODULE__.Supervisor)
    |> Enum.each(fn {_id, pid} ->
        SyncEvent.notify(pid, message)
      end)
  end


  # Attribute API (delegates to attribute-management behaviour)


  def has_attribute?(entity, attribute_type), do: Attribute.has?(entity, attribute_type)


  def fetch_attribute(entity, attribute_type), do: Attribute.fetch(entity, attribute_type)


  def fetch_attribute!(entity, attribute_type), do: Attribute.fetch!(entity, attribute_type)


  def get_attribute(entity, attribute_type), do: Attribute.get(entity, attribute_type)


  def get_and_update_attribute(entity, attribute_type, modifier), do: Attribute.get_and_update(entity, attribute_type, modifier)


  def take_attributes(entity, attribute_types), do: Attribute.take(entity, attribute_types)


  def put_attribute(entity, attribute), do: Attribute.put(entity, attribute)


  def update_attribute(entity, attribute_type, modifier), do: Attribute.update(entity, attribute_type, modifier)


  def remove_attribute(entity, attribute_type), do: Attribute.remove(entity, attribute_type)


  @doc """
  Takes a function that takes the entities current attributes and returns new attributes,
  replaces the entities attributes with these new ones and replies with the new ones.
  """
  def attribute_transaction(entity, modifier), do: Attribute.transaction(entity, modifier)


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


  # Listeners API


  def add_attribute_listener(entity, listener_pid, initial_report \\ true) when is_pid(listener_pid),
  do: AttributeNotify.add_listener(entity, listener_pid, initial_report)


  def remove_attribute_listener(entity, listener_pid) when is_pid(listener_pid),
  do: AttributeNotify.remove_listener(entity, listener_pid)


  # Internal


  defp lookup_and_do(entity_id, fun) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, e} -> fun.(e)
      _        -> :error
    end
  end
end
