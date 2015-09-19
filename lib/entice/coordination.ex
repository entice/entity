defmodule Entice.Entity.Coordination do
  @moduledoc """
  Observes entities and propagates their state changes to different channels

  Your entity will always receive 3 different kinds of messages:

      {:entity_join, %{entity_id: id, attributes: %{} = inital_attributes}}
      {:entity_change, %{entity_id: id, added: %{} = added_attributes, changed: %{} = changed_attributes, removed: %{} = removed_attributes}}
      {:entity_leave, %{entity_id: id, attributes: %{} = last_attributes}}

  You can also passively observe from a standard process and receive those messages.
  """
  require Logger
  alias Entice.Entity.Coordination
  alias Entice.Entity


  def start(), do: :pg2.create(__MODULE__)


  def register(entity_id) when not is_pid(entity_id), do: register(Entity.fetch!(entity_id))
  def register(entity) do
    :pg2.join(__MODULE__, entity)
    Entity.put_behaviour(entity, Coordination.Behaviour, [])
  end


  def register_observer(pid) when is_pid(pid) do
    :pg2.join(__MODULE__, pid)
    notify_observe(pid)
  end


  # Internal API


  @doc "This might fail silently. This is because entities might have died by the time we message them"
  def notify(entity, message) when is_pid(entity), do: send(entity, message)
  def notify(nil, _message),                       do: {:error, :entity_nil}
  def notify(entity_id, message),                  do: notify(Entity.get(entity_id), message)


  def notify_all(message) do
    :pg2.get_members(__MODULE__) |> Enum.map(
      fn pid -> send(pid, message) end)
  end


  def notify_join(entity_id, %{} = attributes) when not is_pid(entity_id),
  do: notify_all({:entity_join, %{entity_id: entity_id, attributes: attributes}})


  def notify_change(entity_id, {%{} = added, %{} = changed, %{} = removed}) when not is_pid(entity_id),
  do: notify_all({:entity_change, %{entity_id: entity_id, added: added, changed: changed, removed: removed}})


  def notify_leave(entity_id, %{} = attributes) when not is_pid(entity_id),
  do: notify_all({:entity_leave, %{entity_id: entity_id, attributes: attributes}})


  def notify_observe(pid) when is_pid(pid),
  do: notify_all({:observer_join, %{observer: pid}})


  # This should be replaced by another process that does the monitoring from the outside,
  # since we're cluttering the entity with behaviours and it gets increasingly complex
  defmodule Behaviour do
    use Entice.Entity.Behaviour
    alias Entice.Entity.Coordination
    alias Entice.Entity

    def init(%Entity{attributes: attribs} = entity, _args) do
      Coordination.notify_join(entity.id, attribs)
      {:ok, entity}
    end


    def handle_event({:entity_join, %{entity_id: sender_entity, attributes: _attrs}}, %Entity{attributes: attribs} = entity) do
      Coordination.notify(sender_entity, {:entity_join, %{entity_id: entity.id, attributes: attribs}}) # announce ourselfes to the new entity
      {:ok, entity}
    end

    def handle_event({:observer_join, %{observer: sender_pid}}, %Entity{attributes: attribs} = entity) do
      send(sender_pid, {:entity_join, %{entity_id: entity.id, attributes: attribs}}) # announce ourselfes to the new observer
      {:ok, entity}
    end


    def handle_change(%Entity{attributes: old_attributes}, %Entity{attributes: new_attributes} = entity) do
      change_set = diff(old_attributes, new_attributes)
      if not_empty?(change_set), do: Coordination.notify_change(entity.id, change_set)
      :ok
    end


    def terminate(_reason, %Entity{attributes: attribs} = entity) do
      Coordination.notify_leave(entity.id, attribs)
      {:ok, entity}
    end


    # internal


    defp diff(old_attrs, new_attrs) do
      missing = old_attrs |> Map.take(Map.keys(old_attrs) -- Map.keys(new_attrs))
      {both, added} = Map.split(new_attrs, Map.keys(old_attrs))
      changed =
        both
        |> Map.keys
        |> Enum.filter_map(
            fn key -> old_attrs[key] != new_attrs[key] end,
            fn key -> {key, new_attrs[key]} end)
        |> Enum.into(%{})
      {added, changed, missing}
    end


    defp not_empty?({added, changed, removed}),
    do: [added, changed, removed] |> Enum.any?(&(not Enum.empty?(&1)))
  end
end
