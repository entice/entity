defmodule Entice.Entity.Server do
  @moduledoc """
  Serves a single entity. Implements the basic entity event functionality.
  """
  use GenServer
  alias Entice.Entity
  alias Entice.Entity.Behaviour
  import Map


  @doc """
  Will be called by the supervisor
  """
  def start_link(id, attributes, opts \\ []),
  do: GenServer.start_link(__MODULE__, %Entity{id: id, attributes: attributes}, opts)


  def init(%Entity{} = state), do: {:ok, state}


  # attribute server


  def handle_call({:has_attribute, attr_type}, _from, %Entity{attributes: attrs} = state),
  do: {:reply, attrs |> has_key?(attr_type), state}


  def handle_call({:fetch_attribute, attr_type}, _from, %Entity{attributes: attrs} = state),
  do: {:reply, attrs |> fetch(attr_type), state}


  def handle_call(msg, from, state), do: super(msg, from, state)


  def handle_cast({:put_attribute, %{__struct__: attr_type} = attr}, %Entity{attributes: attrs} = state),
  do: {:noreply, %Entity{state | attributes: attrs |> put(attr_type, attr)}}


  def handle_cast({:update_attribute, attr_type, modifier}, %Entity{attributes: attrs} = state),
  do: {:noreply,
    if attrs |> has_key?(attr_type) do
      %Entity{state | attributes: attrs |> update!(attr_type, modifier)}
    else
      state
    end}


  def handle_cast({:remove_attribute, attr_type}, %Entity{attributes: attrs} = state),
  do: {:noreply, %Entity{state | attributes: attrs |> delete(attr_type)}}


  # behaviour server


  def handle_cast({:put_behaviour, behaviour, args}, %Entity{behaviour_manager: manager, attributes: attrs} = state) do
    {:ok, man, attr} = Behaviour.Manager.put_handler(manager, behaviour, attrs, args)
    {:noreply, %Entity{state | behaviour_manager: man, attributes: attr}}
  end


  def handle_cast({:remove_behaviour, behaviour}, %Entity{behaviour_manager: manager, attributes: attrs} = state) do
    {:ok, man, attr} = Behaviour.Manager.remove_handler(manager, behaviour, attrs)
    {:noreply, %Entity{state | behaviour_manager: man, attributes: attr}}
  end


  def handle_cast(msg, state), do: super(msg, state)


  def handle_info(event, %Entity{behaviour_manager: manager, attributes: attrs} = state) do
    {:ok, man, attr} = Behaviour.Manager.notify(manager, event, attrs)
    {:noreply, %Entity{state | behaviour_manager: man, attributes: attr}}
  end
end
