defmodule Entice.Entity.Behaviour do
  @moduledoc """
  A behaviour is generic event handler that can be injected into an entity.
  This handler can then act when the entity receives notifications, and
  can manipulate the entities state. (SyncEvent handler wrapper currently)
  """

  defmacro __using__(_) do
    quote do
      use Entice.Utils.SyncEvent
      alias Entice.Entity

      def has_attribute?(%Entity{attributes: attrs}, attribute_type) when is_atom(attribute_type),
      do: Map.has_key?(attrs, attribute_type)

      def fetch_attribute(%Entity{attributes: attrs}, attribute_type) when is_atom(attribute_type),
      do: Map.fetch(attrs, attribute_type)

      def fetch_attribute!(%Entity{attributes: attrs}, attribute_type) when is_atom(attribute_type),
      do: Map.fetch!(attrs, attribute_type)

      def get_attribute(%Entity{attributes: attrs}, attribute_type) when is_atom(attribute_type),
      do: Map.get(attrs, attribute_type)

      def put_attribute(%Entity{attributes: attrs} = entity, %{__struct__: attribute_type} = attribute),
      do: %Entity{entity | attributes: Map.put(attrs, attribute_type, attribute)}

      def update_attribute(%Entity{attributes: attrs} = entity, attribute_type, modifier)
      when is_atom(attribute_type) do
        case Map.has_key?(attrs, attribute_type) do
          true -> %Entity{entity | attributes: Map.update!(attrs, attribute_type, modifier)}
          false -> entity
        end
      end

      def remove_attribute(%Entity{attributes: attrs} = entity, attribute_type) when is_atom(attribute_type),
      do: %Entity{entity | attributes: Map.delete(attrs, attribute_type)}
    end
  end
end
