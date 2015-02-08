defmodule Entice.Entity.Behaviour do
  @moduledoc """
  A behaviour is generic event handler that can be injected into an entity.
  This handler can then act when the entity receives handle_info calls, and
  can manipulate the entities state (as given by its attributes).
  Idea more or less taken from gen_server, gen_event and the the like.
  The behaviour will be initialized by the entity upon creation
  """

  defmacro __using__(_) do
    quote do
      def init(args), do: {:ok, args}

      def handle_event(event, attributes, state), do: {:ok, attributes, state}

      def terminate(_reason, _attributes, _state), do: {:ok, attributes}

      defoverridable [init: 1, handle_event: 3, terminate: 3]
    end
  end

  def event(behaviour, event, attributes, state) do
    try do
      apply(behaviour, :handle_event, [event, attributes, state])
    catch
      _, _ -> {:ok, attributes, state}
    end
  end
end
