defmodule Entice.Cynosure.World do
  @moduledoc """
  World is an event manager for entities and their behaviours.
  Basically, entity is a map of attributes, the behaviours are bound to an
  entity and react to any event they like. When a new entity is created the behaviours
  are linked to it by the world automatically.
  Based on: http://elixir-lang.org/getting_started/mix_otp/5.html
  """
  use GenServer
  alias Entice.Cynosure.Entity
  alias Entice.Cynosure.World

  @type entity_id :: String.t

  defstruct(
    event_manager: nil,
    entity_supervisor: nil,
    entity_ids: %{},
    entity_refs: %{})

  ## Client API

  def start_link(event_manager, entity_supervisor, opts \\ []) do
    GenServer.start_link(__MODULE__, {event_manager, entity_supervisor}, opts)
  end

  def stop(server), do: GenServer.call(server, :stop)


  @spec create_entity(GenServer.server) :: {:ok, entity_id, pid}
  def create_entity(server) do
    entity_id = UUID.uuid1()
    entity = GenServer.call(server, {:create_entity, entity_id, %{}})
    {:ok, entity_id, entity}
  end


  @spec inject_entity(GenServer.server, entity_id, Map) :: {:ok, entity_id, pid}
  def inject_entity(server, entity_id, attributes) do
    entity = GenServer.call(server, {:create_entity, entity_id, attributes})
    {:ok, entity_id, entity}
  end


  @spec lookup_entity(GenServer.server, entity_id) :: {:ok, pid}
  def lookup_entity(server, entity_id) do
    {:ok, entity} = GenServer.call(server, {:lookup_entity, entity_id})
    {:ok, entity_id, entity}
  end


  ## Server API

  def init({event_manager, entity_supervisor}) do
    entity_ids = HashDict.new
    entity_refs = HashDict.new
    {:ok, %World{
      event_manager: event_manager,
      entity_supervisor: entity_supervisor,
      entity_ids: entity_ids,
      entity_refs: entity_refs}}
  end


  def handle_call({:create_entity, entity_id, attributes}, _from, state) do
    {:ok, entity} = Entity.Supervisor.start_entity(
      state.entity_supervisor,
      entity_id,
      state.event_manager,
      [attributes: attributes])

    entity_ids = Map.put(state.entity_ids, entity_id, entity)
    ref = Process.monitor(entity)
    entity_refs = Map.put(state.entity_refs, ref, entity_id)

    GenEvent.sync_notify(state.event_manager, {:create_entity, entity_id, entity})
    {:reply, entity, %{state | entity_ids: entity_ids, entity_refs: entity_refs}}
  end


  def handle_call({:lookup_entity, entity_id}, _from, state) do
    {:reply, Map.fetch(state.entity_ids, entity_id), state}
  end


  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end


  # handle crashed entities...
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {id, entity_refs} = Map.pop(state.entity_refs, ref)
    entity_ids = Map.delete(state.entity_ids, id)
    {:noreply, %{state | entity_ids: entity_ids, entity_refs: entity_refs}}
  end

  def handle_info(_msg, state), do: {:noreply, state}
end
