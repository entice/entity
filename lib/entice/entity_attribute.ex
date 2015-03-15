defmodule Entice.Entity.Attribute do
  @moduledoc """
  A convenience behaviour that allows client code to access the
  entity's attributes directly. This can be used to avoid
  re-implementing the same behaviours over and over again.
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


  def get(entity, attribute_type) when is_atom(attribute_type),
  do: Entity.call(entity, Attribute.Behaviour, {:attribute_get, attribute_type})


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

    def handle_event({:attribute_put, attribute}, entity),
    do: {:ok, entity |> put_attribute(attribute)}

    def handle_event({:attribute_update, attribute_type, modifier}, entity),
    do: {:ok, entity |> update_attribute(attribute_type, modifier)}

    def handle_event({:attribute_remove, attribute_type}, entity),
    do: {:ok, entity |> remove_attribute(attribute_type)}

    def handle_call({:attribute_has, attribute_type}, entity),
    do: {:ok, entity |> has_attribute?(attribute_type), entity}

    def handle_call({:attribute_fetch, attribute_type}, entity),
    do: {:ok, entity |> fetch_attribute(attribute_type), entity}

    def handle_call({:attribute_get, attribute_type}, entity),
    do: {:ok, entity |> get_attribute(attribute_type), entity}

    def handle_call({:attribute_get_and_update, attribute_type, modifier}, entity) do
      new_entity = entity |> update_attribute(attribute_type, modifier)
      {:ok, new_entity |> get_attribute(attribute_type), new_entity}
    end
  end
end
