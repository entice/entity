defmodule Entice.Entity.Behaviour.Manager do
  alias Entice.Entity.Behaviour
  import Map

  def init, do: %{}


  def put_handler(manager, behaviour, entity_id, attributes, args \\ []) when is_atom(behaviour) do
    {:ok, new_attr, state} = Behaviour.init(behaviour, entity_id, attributes, args)
    {:ok, manager |> put(behaviour, state), new_attr}
  end


  def remove_handler(manager, behaviour, attributes) when is_atom(behaviour) do
    case manager |> fetch(behaviour) do
      {:error, _}  -> {:ok, manager, attributes}
      {:ok, state} ->
        {:ok, new_attr} = Behaviour.terminate(behaviour, :remove_handler, attributes, state)
        {:ok, manager |> delete(behaviour), new_attr}
    end
  end


  def notify(manager, event, attributes),
  do: notify_internal(manager |> to_list, manager, event, attributes)


  defp notify_internal([], new_manager, _event, attributes), do: {:ok, new_manager, attributes}
  defp notify_internal([{behaviour, state} | t], new_manager, event, attributes) do
    case Behaviour.handle_event(behaviour, event, attributes, state) do
      {:ok, new_attr, new_state} ->
        notify_internal(t, new_manager |> put(behaviour, new_state), event, new_attr)
      _ ->
        notify_internal(t, new_manager, event, attributes)
    end
  end
end
