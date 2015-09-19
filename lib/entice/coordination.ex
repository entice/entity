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


  def register_entity(entity_id) when not is_pid(entity_id), do: register_entity(Entity.fetch!(entity_id))
  def register_entity(entity) do
    :pg2.join(__MODULE__, entity)
    Entity.put_behaviour(entity, Coordination.Behaviour, [])
  end


  def register_observer(pid) when is_pid(pid) do
    :pg2.join(__MODULE__, pid)
    notify_observe(pid)
  end


  # Internal API


  def notify_join(entity_id, %{} = attributes) when not is_pid(entity_id),
  do: notify_internal(entity_id, :entity_join, attributes)


  def notify_change(entity_id, {%{}, %{}, %{}} = attributes) when not is_pid(entity_id),
  do: notify_internal(entity_id, :entity_change, attributes)


  def notify_leave(entity_id, %{} = attributes) when not is_pid(entity_id),
  do: notify_internal(entity_id, :entity_leave, attributes)


  def notify_observe(pid) when is_pid(pid),
  do: notify_internal(pid, :observer_join, nil)


  defp notify_internal(entity, event, attributes) do
    :pg2.get_members(__MODULE__) |> Enum.map(
      fn pid -> send pid, prepare_message(entity, event, attributes) end)
  end


  defp prepare_message(entity, event, {added, changed, removed}),
  do: {event, %{entity_id: entity, added: added, changed: changed, removed: removed}}

  defp prepare_message(entity, event, other),
  do: {event, %{entity_id: entity, attributes: other}}


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
      Entity.notify(sender_entity, {:entity_join, %{entity_id: entity.id, attributes: attribs}}) # announce ourselfes to the new entity
      {:ok, entity}
    end

    def handle_event({:observer_join, %{entity_id: sender_pid}}, %Entity{attributes: attribs} = entity) do
      send sender_pid, {:entity_join, %{entity_id: entity.id, attributes: attribs}} # announce ourselfes to the new observer
      {:ok, entity}
    end


    def handle_change(%Entity{attributes: old_attributes}, %Entity{attributes: new_attributes}) do
      change_set = diff(old_attributes, new_attributes)
      if not_empty?(change_set), do: Coordination.notify_change(self(), change_set)
      :ok
    end


    def terminate(_reason, %Entity{attributes: attribs} = entity) do
      Coordination.notify_leave(entity.id, attribs)
      {:ok, entity}
    end


    # internal


    defp diff(old_attrs, new_attrs),
    do: diff_internal(old_attrs |> Map.delete(AttributeNotify), new_attrs |> Map.delete(AttributeNotify))

    defp diff_internal(old_attrs, new_attrs) do
      missing = Map.keys(old_attrs) -- Map.keys(new_attrs)
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
