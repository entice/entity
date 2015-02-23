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


  def init(%Entity{} = state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end


  # attribute server


  def handle_call({:has_attribute, attr_type}, _from, %Entity{attributes: attrs} = state),
  do: {:reply, attrs |> has_key?(attr_type), state}


  def handle_call({:fetch_attribute, attr_type}, _from, %Entity{attributes: attrs} = state),
  do: {:reply, attrs |> fetch(attr_type), state}


  def handle_call(msg, from, state), do: super(msg, from, state)


  def handle_cast({:put_attribute, %{__struct__: attr_type} = attr}, %Entity{attributes: attrs} = state) do
    new_attrs = attrs |> put(attr_type, attr)
    notify_attributes_changed(attrs, new_attrs)
    {:noreply, %Entity{state | attributes: new_attrs}}
  end


  def handle_cast({:update_attribute, attr_type, modifier}, %Entity{attributes: attrs} = state) do
    new_attrs =
      case attrs |> has_key?(attr_type) do
        true  -> attrs |> update!(attr_type, modifier)
        false -> attrs
      end
    notify_attributes_changed(attrs, new_attrs)
    {:noreply, %Entity{state | attributes: new_attrs}}
  end


  def handle_cast({:remove_attribute, attr_type}, %Entity{attributes: attrs} = state) do
    new_attrs = attrs |> delete(attr_type)
    notify_attributes_changed(attrs, new_attrs)
    {:noreply, %Entity{state | attributes: new_attrs}}
  end


  # behaviour server


  def handle_cast({:put_behaviour, behaviour, args}, %Entity{id: id, behaviour_manager: manager, attributes: attrs} = state) do
    {:ok, man, new_attrs} = Behaviour.Manager.put_handler(manager, behaviour, id, attrs, args)
    notify_attributes_changed(attrs, new_attrs)
    {:noreply, %Entity{state | behaviour_manager: man, attributes: new_attrs}}
  end


  def handle_cast({:remove_behaviour, behaviour}, %Entity{behaviour_manager: manager, attributes: attrs} = state) do
    {:ok, man, new_attrs} = Behaviour.Manager.remove_handler(manager, behaviour, attrs)
    notify_attributes_changed(attrs, new_attrs)
    {:noreply, %Entity{state | behaviour_manager: man, attributes: new_attrs}}
  end


  def handle_cast(msg, state), do: super(msg, state)


  def handle_info(event, %Entity{behaviour_manager: manager, attributes: attrs} = state) do
    {:ok, man, new_attrs} = Behaviour.Manager.notify(manager, event, attrs)
    notify_attributes_changed(attrs, new_attrs)
    {:noreply, %Entity{state | behaviour_manager: man, attributes: new_attrs}}
  end


  # termination


  def terminate(_reason, %Entity{behaviour_manager: manager, attributes: attrs}) do
    Behaviour.Manager.remove_all(manager, attrs)
    :ok
  end


  # internal API

  defp notify_attributes_changed(old, new) when old == new, do: :ok
  defp notify_attributes_changed(old, new) when old != new,
  do: send(self, {:attributes_changed, old, new})
end
