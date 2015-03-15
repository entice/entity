defmodule Entice.Entity.Attribute do
  @moduledoc """
  A convenience behaviour that allows client code to access the
  entitie's attributes directy.
  """
  alias Entice.Entity
  alias Entice.Entity.Attribute


  def register(entity),
  do: Entity.put_behaviour(entity, Attribute.Behaviour, [])

  def unregister(entity),
  do: Entity.remove_behaviour(entity, Attribute.Behaviour)


  def has?(entity, attribute_type) when is_atom(attribute_type),
  do: Entity.call(entity, Attribute.Behaviour, {:attribute_has, attribute_type})


  def fetch(entity, attribute_type) when is_atom(attribute_type),
  do: Entity.call(entity, Attribute.Behaviour, {:attribute_fetch, attribute_type})


  def fetch!(entity, attribute_type) when is_atom(attribute_type) do
    case Entity.call(entity, Attribute.Behaviour, {:attribute_fetch, attribute_type}) do
      {:ok, value} -> value
      :error       -> raise KeyError, key: attribute_type, term: entity
    end
  end


  def get_and_update(entity, attribute_type, modifier) when is_atom(attribute_type),
  do: Entity.call(entity, Attribute.Behaviour, {:attribute_get_and_update, attribute_type, modifier})


  def put(entity, %{__struct__: _} = attribute),
  do: Entity.notify(entity, {:attribute_put, attribute})


  def update(entity, attribute_type, modifier) when is_atom(attribute_type),
  do: Entity.notify(entity, {:attribute_update, attribute_type, modifier})


  def remove(entity, attribute_type) when is_atom(attribute_type),
  do: Entity.notify(entity, {:attribute_remove, attribute_type})


  defmodule Behaviour do
    use Entice.Entity.Behaviour
    import Map

    def handle_event({:attribute_put, attribute}, %Entity{attributes: attrs} = state),
    do: {:ok, %{state | attributes: attrs |> put(attribute.__struct__, attribute)}}

    def handle_event({:attribute_update, attribute_type, modifier}, %Entity{attributes: attrs} = state) do
      case attrs |> fetch(attribute_type) do
        {:ok, attr}  -> {:ok, %{state | attributes: attrs |> put(attribute_type, modifier.(attr))}}
        _            -> {:ok, state}
      end
    end

    def handle_event({:attribute_remove, attribute_type}, %Entity{attributes: attrs} = state),
    do: {:ok, %{state | attributes: attrs |> delete(attribute_type)}}

    def handle_call({:attribute_has, attribute_type}, %Entity{attributes: attrs} = state),
    do: {:ok, attrs |> has_key?(attribute_type), state}

    def handle_call({:attribute_fetch, attribute_type}, %Entity{attributes: attrs} = state),
    do: {:ok, attrs |> fetch(attribute_type), state}

    def handle_call({:attribute_get_and_update, attribute_type, modifier}, %Entity{attributes: attrs} = state) do
      new_state =
        case attrs |> fetch(attribute_type) do
          {:ok, attr}  -> %{state | attributes: attrs |> put(attribute_type, modifier.(attr))}
          _            -> state
        end
      {:ok, new_state.attributes |> get(attribute_type), new_state}
    end
  end
end
