defmodule Entice.Cynosure.Entity do
  @moduledoc """
  Data-only entity built upon an Agent.
  """
  import Map
  alias Entice.Cynosure.Entity


  @typedoc """
  Entity is either its agents directly, or its the entity id, accessible from the world.
  When we get an entity id, we delegate the lookup of the entity to the world first.
  """
  @type entity :: Agent.agent
  @type entity_id :: String.t
  @type world :: atom
  @type attribute_type :: atom


  defstruct(
    id: "",
    world: nil,
    attributes: %{})


  # World-based API


  @doc """
  Will be called by the supervisor
  """
  def start_link(id, world, attributes, opts \\ []) do
    Agent.start_link(
      fn -> %Entity{id: id, world: world, attributes: attributes} end,
      opts)
  end


  @spec start(world, entity_id, Map, list) :: Agent.on_start
  def start(world, entity_id, attributes \\ %{}, opts \\ []) do
    ETSSupervisor.start(world, entity_id, [world, attributes | opts])
    {:ok, entity_id}
  end


  @spec has_attribute?(world, entity_id, attribute_type) :: boolean | {:error, term}
  def has_attribute?(world, entity_id, attribute_type) do
    case ETSSupervisor.lookup(world, entity_id) do
      {:ok, e} -> has_attribute?(e, attribute_type)
      err -> err
    end
  end


  @spec put_attribute(world, entity_id,  %{__struct__: attribute_type}) :: :ok | {:error, term}
  def put_attribute(world, entity_id, attribute) do
    case ETSSupervisor.lookup(world, entity_id) do
      {:ok, e} -> put_attribute(e, attribute)
      err -> err
    end
  end


  @spec get_attribute(world, entity_id,  attribute_type) :: {:ok, any} | {:error, term}
  def get_attribute(world, entity_id, attribute_type) do
    case ETSSupervisor.lookup(world, entity_id) do
      {:ok, e} -> get_attribute(e, attribute_type)
      err -> err
    end
  end


  @spec update_attribute(world, entity_id,  attribute_type, (any -> any)) :: :ok | {:error, term}
  def update_attribute(world, entity_id, attribute_type, modifier) do
    case ETSSupervisor.lookup(world, entity_id) do
      {:ok, e} -> update_attribute(e, attribute_type, modifier)
      err -> err
    end
  end


  @spec remove_attribute(world, entity_id,  attribute_type) :: :ok | {:error, term}
  def remove_attribute(world, entity_id, attribute_type) do
    case ETSSupervisor.lookup(world, entity_id) do
      {:ok, e} -> remove_attribute(e, attribute_type)
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
  end

  defp remove_attribute(entity, attribute_type) do
    Agent.update(entity, fn %Entity{attributes: attrs} = state ->
      %Entity{state | attributes: attrs |> delete(attribute_type)}
    end)
  end
end


defmodule Entice.Cynosure.Entity.Sup do
  @moduledoc """
  Simple entity supervisor that does not restart entities when they despawn.
  """
  alias Entice.Cynosure.Entity

  def start_link(name) do
    ETSSupervisor.Sup.start_link(name, Entity)
  end
end
