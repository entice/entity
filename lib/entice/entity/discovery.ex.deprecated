defmodule Entice.Entity.Discovery do
  @moduledoc """
  This behaviour manages the discovery and undiscovery of entities
  that satisfy certain conditions.
  """
  alias Entice.Entity
  alias Entice.Entity.Trigger


  @doc """
  Sends a `{:discovered, %Entity{...}}` message back to the requester
  when any of all available entities possesses or aquires a certain attribute.
  """
  def discover_attribute(attribute_type, requester_pid)
  when is_atom(attribute_type) and is_pid(requester_pid) do
    attribute_type
    |> create_discovery_trigger(requester_pid)
    |> Trigger.trigger_all
  end


  @doc """
  Sends a `{:undiscovered, %Entity{...}}` message back to the requester
  when an entity that possess a certain attribute loses it.
  """
  def undiscover_attribute(entity, attribute_type, requester_pid)
  when is_atom(attribute_type) and is_pid(requester_pid) do
    attribute_type
    |> create_undiscovery_trigger(requester_pid)
    |> (&Trigger.trigger(entity, &1)).()
  end


  defp create_discovery_trigger(attribute_type, requester_pid) do
    fn %Entity{attributes: attributes} = entity ->
      if attributes |> Map.has_key?(attribute_type) do
        send requester_pid, {:discovered, entity}
        true
      else
        false
      end
    end
  end


  defp create_undiscovery_trigger(attribute_type, requester_pid) do
    callback = fn %Entity{attributes: attributes} = entity ->
      if not (attributes |> Map.has_key?(attribute_type)) do
        send requester_pid, {:undiscovered, entity}
        true
      else
        false
      end
    end
    fn %Entity{attributes: attributes} = entity ->
      if attributes |> Map.has_key?(attribute_type) do
        Trigger.trigger(entity.id, callback)
        true
      else
        true # always trigger, we dont want to wait for the entity to aquire the attr
      end
    end
  end
end
