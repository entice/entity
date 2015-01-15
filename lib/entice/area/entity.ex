defmodule Entice.Area.Entity do
  @moduledoc """
  Data-only entity built upon an Agent.
  """
  import Map
  alias Entice.Area
  alias Entice.Area.Entity
  alias Entice.Area.Util.ETSSupervisor


  @typedoc """
  Entity is either its agents directly, or its the entity id, accessible from the area.
  When we get an entity id, we delegate the lookup of the entity to the area first.
  """
  @type entity :: Agent.agent
  @type entity_id :: String.t
  @type area :: atom
  @type attribute_type :: atom


  defstruct(
    id: "",
    area: nil,
    attributes: %{})


  # World-based API


  @doc """
  Will be called by the supervisor
  """
  def start_link(id, area, attributes, opts \\ []) do
    Agent.start_link(
      fn -> %Entity{id: id, area: area, attributes: attributes} end,
      opts)
  end


  @spec start(area, entity_id, Map, list) :: Agent.on_start
  def start(area, entity_id, attributes \\ %{}, opts \\ []) do
    ETSSupervisor.start(area, entity_id, [area, attributes | opts])
    Area.Evt.entity_added(area, entity_id, attributes)
    {:ok, entity_id}
  end


  @spec stop(area, entity_id) :: :ok
  def stop(area, entity_id) do
    ETSSupervisor.terminate(area, entity_id)
    Area.Evt.entity_removed(area, entity_id)
    :ok
  end


  @spec exists?(area, entity_id) :: boolean
  def exists?(area, entity_id) do
    case ETSSupervisor.lookup(area, entity_id) do
      {:ok, _e} -> true
      _ -> false
    end
  end


  @spec get_entity_dump(area) :: [%{id: entity_id, attributes: Map}]
  def get_entity_dump(area) do
    ETSSupervisor.get_all(area)
    |> Enum.map(fn {_, e} -> e |> Agent.get(&(&1)) end)
    |> Enum.map(
      fn %Entity{id: id, area: _, attributes: attrs} ->
        %{id: id, attributes: attrs}
      end)
  end


  @spec has_attribute?(area, entity_id, attribute_type) :: boolean | {:error, term}
  def has_attribute?(area, entity_id, attribute_type) do
    case ETSSupervisor.lookup(area, entity_id) do
      {:ok, e} -> has_attribute?(e, attribute_type)
      err -> err
    end
  end


  @spec put_attribute(area, entity_id,  %{__struct__: attribute_type}) :: :ok | {:error, term}
  def put_attribute(area, entity_id, attribute) do
    case ETSSupervisor.lookup(area, entity_id) do
      {:ok, e} ->
        put_attribute(e, attribute)
        Area.Evt.attribute_updated(area, entity_id, attribute)
      err -> err
    end
  end


  @spec get_attribute(area, entity_id,  attribute_type) :: {:ok, any} | {:error, term}
  def get_attribute(area, entity_id, attribute_type) do
    case ETSSupervisor.lookup(area, entity_id) do
      {:ok, e} -> get_attribute(e, attribute_type)
      err -> err
    end
  end


  @spec update_attribute(area, entity_id,  attribute_type, (any -> any)) :: {:ok, any} | {:error, term}
  def update_attribute(area, entity_id, attribute_type, modifier) do
    case ETSSupervisor.lookup(area, entity_id) do
      {:ok, e} ->
        case update_attribute(e, attribute_type, modifier) do
          {:ok, a} = res ->
            Area.Evt.attribute_updated(area, entity_id, a)
            res
          err -> err
        end
      err -> err
    end
  end


  @spec remove_attribute(area, entity_id,  attribute_type) :: :ok | {:error, term}
  def remove_attribute(area, entity_id, attribute_type) do
    case ETSSupervisor.lookup(area, entity_id) do
      {:ok, e} ->
        remove_attribute(e, attribute_type)
        Area.Evt.attribute_removed(area, entity_id, attribute_type)
      err -> err
    end
  end



  # Agent-based (internal) API

  defp has_attribute?(entity, attribute_type) do
    Agent.get(entity, fn %Entity{attributes: attrs} ->
      attrs |> has_key?(attribute_type)
    end)
  end

  defp put_attribute(entity, attribute) do
    Agent.update(entity, fn %Entity{attributes: attrs} = state ->
      %Entity{state | attributes: attrs |> put(attribute.__struct__, attribute)}
    end)
  end

  defp get_attribute(entity, attribute_type) do
    Agent.get(entity, fn %Entity{attributes: attrs} ->
      attrs |> fetch(attribute_type)
    end)
  end

  defp update_attribute(entity, attribute_type, modifier) do
    Agent.update(entity, fn %Entity{attributes: attrs} = state ->
      if attrs |> has_key?(attribute_type) do
        %Entity{state | attributes: attrs |> update!(attribute_type, modifier)}
      else
        state
      end
    end)
    get_attribute(entity, attribute_type)
  end

  defp remove_attribute(entity, attribute_type) do
    Agent.update(entity, fn %Entity{attributes: attrs} = state ->
      %Entity{state | attributes: attrs |> delete(attribute_type)}
    end)
  end
end


defmodule Entice.Area.Entity.Sup do
  @moduledoc """
  Simple entity supervisor that does not restart entities when they despawn.
  """
  alias Entice.Area.Entity
  alias Entice.Area.Util.ETSSupervisor

  def start_link(name) do
    ETSSupervisor.Sup.start_link(name, Entity)
  end
end
