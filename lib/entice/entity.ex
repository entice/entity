defmodule Entice.Entity do
  alias GenServer
  alias Entice.Utils.ETSSupervisor
  alias Entice.Entity.Behaviour


  defstruct(
    id: "",
    behaviour_manager: Behaviour.Manager.init,
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


  def notify(entity, message) when is_pid(entity), do: send(entity, message)
  def notify(entity_id, message), do: entity_id |> lookup_and_do(&notify(&1, message))


  # Entity internal attribute API


  def has_attribute?(entity, attribute_type) when is_pid(entity) and is_atom(attribute_type),
  do: GenServer.call(entity, {:has_attribute, attribute_type})

  def has_attribute?(entity_id, attribute_type), do: entity_id |> lookup_and_do(&has_attribute?(&1, attribute_type))


  def fetch_attribute(entity, attribute_type) when is_pid(entity) and is_atom(attribute_type),
  do: GenServer.call(entity, {:fetch_attribute, attribute_type})

  def fetch_attribute(entity_id, attribute_type), do: entity_id |> lookup_and_do(&fetch_attribute(&1, attribute_type))


  def put_attribute(entity, %{__struct__: _} = attribute) when is_pid(entity),
  do: GenServer.cast(entity, {:put_attribute, attribute})

  def put_attribute(entity_id, %{__struct__: _} = attribute), do: entity_id |> lookup_and_do(&put_attribute(&1, attribute))


  def update_attribute(entity, attribute_type, modifier) when is_pid(entity) and is_atom(attribute_type),
  do: GenServer.cast(entity, {:update_attribute, attribute_type, modifier})

  def update_attribute(entity_id, attribute_type, modifier), do: entity_id |> lookup_and_do(&update_attribute(&1, attribute_type, modifier))


  def remove_attribute(entity, attribute_type) when is_pid(entity) and is_atom(attribute_type),
  do: GenServer.cast(entity, {:remove_attribute, attribute_type})

  def remove_attribute(entity_id, attribute_type), do: entity_id |> lookup_and_do(&remove_attribute(&1, attribute_type))


  # Entity internal behaviour API


  def put_behaviour(entity, behaviour, args) when is_pid(entity) and is_atom(behaviour),
  do: GenServer.cast(entity, {:put_behaviour, behaviour, args})


  def remove_behaviour(entity, behaviour) when is_pid(entity) and is_atom(behaviour),
  do: GenServer.cast(entity, {:remove_behaviour, behaviour})


  # internal api

  defp lookup_and_do(entity_id, fun) do
    case ETSSupervisor.lookup(__MODULE__.Supervisor, entity_id) do
      {:ok, e} -> fun.(e)
      _        -> :error
    end
  end
end
