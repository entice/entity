defmodule Entice.Entity.Behaviour do
  @moduledoc """
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


defmodule Entice.Entity.Behaviour.Manager do
  alias Entice.Entity.Behaviour
  import Map

  def init, do: %{}


  def put_handler(manager, behaviour, args \\ []) when is_atom(behaviour) do
    case apply(behaviour, :init, args) do
      {:ok, state} -> manager |> put(behaviour, state)
      _            -> manager
    end
  end


  def remove_handler(manager, behaviour, attributes) when is_atom(behaviour) do
    case manager |> fetch(behaviour) do
      {:error, _}  -> {:ok, manager, attributes}
      {:ok, state} ->
        {:ok, new_attr} = apply(behaviour, :terminate, [:remove_handler, attributes, state])
        {:ok, manager |> delete(behaviour), attributes}
    end
  end


  def notify(manager, event, attributes),
  do: notify_internal(manager |> to_list, manager, event, attributes)


  defp notify_internal([], new_manager, _event, attributes), do: {new_manager, attributes}
  defp notify_internal([{behaviour, state} | t], new_manager, event, attributes) do
    case Behaviour.event(behaviour, event, attributes, state) do
      {:ok, new_attr, new_state} ->
        notify_internal(t, new_manager |> put(behaviour, new_state), event, new_attr)
      _ ->
        notify_internal(t, new_manager, event, attributes)
    end
  end
end
