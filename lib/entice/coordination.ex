defmodule Entice.Entity.Coordination do
  @moduledoc """
  Observes entities and propagates their state changes to different channels

  Your entity will always receive 3 different kinds of messages:

      {:entity_join, entity, %{} = inital_attributes}
      {:entity_change, entity, %{} = added_attributes, %{} = changed_attributes, %{} = removed_attributes}
      {:entity_leave, entity, %{} = last_attributes}

  You can also passively observe from a standard process and receive those messages.
  """

  def start(), do: :pg2.create(__MODULE__)


  def register_entity(entity) when is_pid(entity) do
    :pg2.join(__MODULE__, entity)
    Entity.put_behaviour(Entice.Entity.Coordination.Behaviour)
  end


  def register_observer(pid) when is_pid(pid) do
    :pg2.join(__MODULE__, pid)
    notify_observe(pid)
  end


  def notify_join(entity, %{} = attributes), do: notify(entity, :entity_join, attributes)

  def notify_change(entity, {%{}, %{}, %{}} = attributes), do: notify(entity, :entity_change, attributes)

  def notify_leave(entity, %{} = attributes), do: notify(entity, :entity_leave, attributes)

  def notify_observe(pid), do: notify(pid, :observer_join, nil)


  defp notify(entity, event, attributes) when is_pid(entity),
  do: :pg2.get_members(__MODULE__) |> Enum.each(&(send &1, prepare_message(entity, event, attributes)).())
  defp notify(entity, event, attributes) do
    case Entity.fetch(entity) do
      {:ok, ent} -> notify(ent, event, attributes)
      _          ->
    end
  end


  defp prepare_message(entity, event, {added, changed, removed}), do: {event, entity, added, changed, removed}
  defp prepare_message(entity, event, other),                     do: {event, entity, other}


  # This should be replaced by another process that does the monitoring from the outside,
  # since we're cluttering the entity with behaviours and it gets increasingly complex
  defmodule Behaviour do
    use Entice.Entity.Behaviour
    alias Entice.Entity.Coordination

    def init(%Entity{attributes: attribs} = entity, _args) do
      Coordination.notify_join(self(), attribs)
      {:ok, entity}
    end


    def handle_event({:entity_join, sender_entity, _attrs}, %Entity{attributes: attribs} = entity) do
      Entity.notify(sender_entity, {:entity_join, entity, attribs}) # announce ourselfes to the new entity
      {:ok, entity}
    end

    def handle_event({:observer_join, sender_pid, _}, %Entity{attributes: attribs} = entity) do
      send sender_pid, {:entity_join, entity, attribs} # announce ourselfes to the new observer
      {:ok, entity}
    end


    def handle_change(old_entity, new_entity) do
      change_set = diff(old_entity, new_entity)
      if not_empty?(change_set), do: Coordination.notify_change(self(), change_set)
      :ok
    end


    def terminate(_reason, %Entity{attributes: attribs} = entity) do
      Coordination.notify_leave(self(), attribs)
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
