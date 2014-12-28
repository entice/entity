defmodule Entice.Cynosure.Entity do
  @moduledoc """
  Data-only entity built upon an Agent.
  """
  alias Entice.Cynosure.Entity

  @type entity :: Agent.agent

  defstruct id: "", event_manager: nil, attributes: %{}

  def start_link(id, event_manager, opts \\ []) do
    {attributes, _opts} = Keyword.pop(opts, :attributes, %{})
    Agent.start_link(fn ->
      %Entity{id: id, event_manager: event_manager, attributes: attributes}
    end,
    name: __MODULE__)
  end


  @spec has_attribute?(entity, atom | %{__struct__: atom}) :: boolean
  def has_attribute?(entity, %{__struct__: attribute_type}), do: has_attribute?(entity, attribute_type)
  def has_attribute?(entity, attribute_type) do
    Agent.get(entity, fn %Entity{attributes: attrs} ->
      Map.has_key?(attrs, attribute_type)
    end)
  end


  @spec put_attribute(entity, %{__struct__: atom}) :: :ok
  def put_attribute(entity, attribute) do
    Agent.update(entity, fn %Entity{attributes: attrs} = state ->
      %Entity{state | attributes: Map.put(attrs, attribute.__struct__, attribute)}
    end)
  end


  @spec get_attribute(entity, atom | %{__struct__: atom}) :: {:ok, any} | :error
  def get_attribute(entity, %{__struct__: attribute_type}), do: get_attribute(entity, attribute_type)
  def get_attribute(entity, attribute_type) do
    Agent.get(entity, fn %Entity{attributes: attrs} ->
      Map.fetch(attrs, attribute_type)
    end)
  end


  @spec update_attribute(entity, atom, (any -> any)) :: :ok
  def update_attribute(entity, attribute_type, modifier) do
    Agent.update(entity, fn %Entity{attributes: attrs} = state ->
      if Map.has_key?(attrs, attribute_type) do
        %Entity{state | attributes: Map.update!(attrs, attribute_type, modifier)}
      else
        state
      end
    end)
  end


  @spec remove_attribute(entity, atom | %{__struct__: atom}) :: :ok
  def remove_attribute(entity, %{__struct__: attribute_type}), do: remove_attribute(entity, attribute_type)
  def remove_attribute(entity, attribute_type) do
    Agent.update(entity, fn %Entity{attributes: attrs} = state ->
      %Entity{state | attributes: Map.delete(attrs, attribute_type)}
    end)
  end
end
