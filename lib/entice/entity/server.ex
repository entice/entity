defmodule Entice.Entity.Server do
  @moduledoc """
  Serves a single entity. Implements the basic entity event functionality.
  """
  use GenServer
  alias Entice.Entity
  import Map


  @doc """
  Will be called by the supervisor
  """
  def start_link(id, attributes, opts \\ []),
  do: GenServer.start_link(__MODULE__, %Entity{id: id, attributes: attributes}, opts)


  def init(%Entity{} = state), do: {:ok, state}


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


  def handle_cast(msg, state), do: super(msg, state)
end
