defmodule Entice.Entity.AttributeNotify do
  @moduledoc """
  Report changes to attributes of an entity back to listeners.
  Think of this as a very simple way to avoid having to reimplement behaviours that
  are only listening for state changes of the entity.

  Listener processes are monitored and dead listeners will be removed.

  If the entity adds, changes or removes any of its attributes, listeners will
  be notified with a changeset:

      {:attribute_notification, %{
        entity_id: "your-entity-id",
        added: %{Attribute1 => %Attribute1{...}, ...},
        changed: %{Attribute2 => %Attribute2{...}, ...},
        removed: [Attribute3, ...]}}

  """
  alias Entice.Entity
  alias Entice.Entity.AttributeNotify


  defstruct listeners: []


  def register(entity),
  do: Entity.put_behaviour(entity, AttributeNotify.Behaviour, [])


  def unregister(entity),
  do: Entity.remove_behaviour(entity, AttributeNotify.Behaviour)


  def add_listener(entity_id, listener_pid, initial_report \\ true),
  do: Entity.notify(entity_id, {:attribute_add_listener, listener_pid, initial_report})


  def remove_listener(entity_id, listener_pid),
  do: Entity.notify(entity_id, {:attribute_remove_listener, listener_pid})


  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, _args),
    do: {:ok, entity |> put_attribute(%AttributeNotify{})}


    def handle_event(
        {:attribute_add_listener, listener_pid, initial_report},
        %Entity{id: id, attributes: %{AttributeNotify => %AttributeNotify{listeners: listeners}}} = entity) do
      if initial_report do
        listener_pid |> send({:attribute_notification, %{
          entity_id: id,
          added: entity.attributes,
          changed: %{},
          removed: []}})
      end
      Process.monitor(listener_pid)
      {:ok, entity |> put_attribute(%AttributeNotify{listeners: [listener_pid | listeners]})}
    end


    def handle_event(
        {:attribute_remove_listener, listener_pid},
        %Entity{attributes: %{AttributeNotify => %AttributeNotify{listeners: listeners}}} = entity),
    do: {:ok, entity |> put_attribute(%AttributeNotify{listeners: listeners -- [listener_pid]})}


    def handle_event(
        {:DOWN, _ref, _type, listener_pid, _info},
        %Entity{attributes: %{AttributeNotify => %AttributeNotify{listeners: listeners}}} = entity),
    do: {:ok, entity |> put_attribute(%AttributeNotify{listeners: listeners -- [listener_pid]})}


    def handle_change(old_entity, %Entity{id: id, attributes: %{AttributeNotify => %AttributeNotify{listeners: listeners}}} = new_entity) do
      msg = %{entity_id: id} |> Map.merge(diff(old_entity.attributes, new_entity.attributes))
      for listener_pid <- listeners, not_empty?(msg),
      do: listener_pid |> send({:attribute_notification, msg})
      :ok
    end


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
      %{added: added, changed: changed, removed: missing}
    end


    defp not_empty?(%{added: added, changed: changed, removed: removed}) do
      [added, changed, removed] |> Enum.any?(&(not Enum.empty?(&1)))
    end
  end
end
