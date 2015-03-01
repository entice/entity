defmodule Entice.Entity.Behaviour do
  @moduledoc """
  A behaviour is generic event handler that can be injected into an entity.
  This handler can then act when the entity receives handle_info calls, and
  can manipulate the entities state (as given by its attributes).
  Idea more or less taken from gen_server, gen_event and the the like.
  The behaviour will be initialized by the entity upon creation
  """
  use Behaviour


  defcallback init(entity_id :: String.t, attributes :: map, state :: term) ::
    {:ok, attributes :: map, state :: term} |
    {:error, reason :: term}


  defcallback handle_event(event :: String.t, attributes :: map, state :: term) ::
    {:ok, attributes :: map, state :: term} |
    {:become, new_behaviour :: atom, args :: term, attributes :: map, state :: term} |
    {:stop, reason :: term, attributes :: map, state :: term} |
    {:error, reason :: term}


  defcallback handle_change(old_attributes :: map, new_attributes :: map, state :: term) ::
    {:ok, attributes :: map, state :: term} |
    {:become, new_behaviour :: atom, args :: term, attributes :: map, state :: term} |
    {:stop, reason :: term, attributes :: map, state :: term} |
    {:error, reason :: term}


  defcallback terminate(reason :: term, attributes :: map, state :: term) ::
    {:ok, attributes :: map} |
    {:error, reason :: term}


  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      def init(entity_id, attributes, args), do: {:ok, attributes, args}

      def handle_event(event, attributes, state), do: {:ok, attributes, state}

      def handle_change(old_attributes, new_attributes, state), do: {:ok, new_attributes, state}

      def terminate(_reason, attributes, _state), do: {:ok, attributes}

      defoverridable [init: 3, handle_event: 3, handle_change: 3, terminate: 3]
    end
  end


  def init(behaviour, entity_id, attributes, state) do
    apply(behaviour, :init, [entity_id, attributes, state])
  end


  def handle_event(behaviour, {:attributes_changed, old_attributes, new_attributes}, attributes, state)
  when new_attributes == attributes do
    try do
      apply(behaviour, :handle_change, [old_attributes, new_attributes, state])
    rescue
      _ in FunctionClauseError -> {:ok, new_attributes, state}
    end
  end

  def handle_event(behaviour, event, attributes, state) do
    try do
      apply(behaviour, :handle_event, [event, attributes, state])
    rescue
      _ in FunctionClauseError -> {:ok, attributes, state}
    end
  end


  def terminate(behaviour, reason, attributes, state) do
    apply(behaviour, :terminate, [reason, attributes, state])
  end
end
