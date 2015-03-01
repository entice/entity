defmodule Entice.Entity.Behaviour.Manager do
  require Logger
  alias Entice.Entity.Behaviour
  import Map


  def init, do: %{}


  def has_handler?(manager, behaviour),
  do: manager |> has_key?(behaviour)


  def put_handler(entity_id, manager, behaviour, attributes, args \\ []) when is_atom(behaviour) do
    Behaviour.init(behaviour, entity_id, attributes, args)
    |> handle_result(entity_id, manager, behaviour)
  end


  def remove_handler(entity_id, manager, behaviour, attributes) when is_atom(behaviour) do
    case manager |> fetch(behaviour) do
      :error       -> {:ok, manager, attributes}
      {:ok, state} ->
        {:ok, new_manager, new_attributes} =
          Behaviour.terminate(behaviour, :remove_handler, attributes, state)
          |> handle_exit_result(entity_id, manager, behaviour)

        {:ok, new_manager |> delete(behaviour), new_attributes}
    end
  end


  def remove_all(entity_id, manager, attributes),
  do: remove_all_internal(manager |> keys, entity_id, manager, attributes)

  defp remove_all_internal([], _entity_id, manager, attributes),
  do: {:ok, manager, attributes}

  defp remove_all_internal([behaviour | _], entity_id, manager, attributes) do
    {:ok, new_manager, new_attr} = remove_handler(entity_id, manager, behaviour, attributes)
    remove_all(entity_id, new_manager, new_attr)
  end


  def notify(entity_id, manager, event, attributes),
  do: notify_internal(manager |> to_list, entity_id, manager, event, attributes)

  defp notify_internal([], _entity_id, manager, _event, attributes),
  do: {:ok, manager, attributes}

  defp notify_internal([{behaviour, state} | tail], entity_id, manager, event, attributes) do
    {:ok, new_manager, new_attributes} =
      Behaviour.handle_event(behaviour, event, attributes, state)
      |> handle_result(entity_id, manager, behaviour)

    notify_internal(tail, entity_id, new_manager, event, new_attributes)
  end


  # Internal


  defp handle_result({:ok, attributes, state}, _entity_id, manager, behaviour),
  do: {:ok, manager |> put(behaviour, state), attributes}

  defp handle_result({:stop, reason, attributes, state}, entity_id, manager, behaviour) do
    Logger.debug fn -> "Stopping behaviour #{inspect behaviour} because of: #{inspect reason}" end
    remove_handler(entity_id, manager |> put(behaviour, state), behaviour, attributes)
  end

  defp handle_result({:become, new_behaviour, args, attributes, state}, entity_id, manager, behaviour) do
    Logger.debug fn -> "Replacing behaviour #{inspect behaviour} with #{inspect new_behaviour}." end
    {:ok, new_manager, new_attributes} = remove_handler(entity_id, manager |> put(behaviour, state), behaviour, attributes)
    put_handler(entity_id, new_manager, new_behaviour, new_attributes, args)
  end

  defp handle_result({:error, reason}, _entity_id, _manager, behaviour),
  do: raise "Error in behaviour #{inspect behaviour} because of: #{inspect reason}"

  defp handle_result(return, _entity_id, _manager, _behaviour),
  do: raise "Return was incorrect. Check the API documentation for behaviours. Got: #{inspect return}"


  # On terminate...

  defp handle_exit_result({:ok, attributes}, _entity_id, manager, behaviour),
  do: {:ok, manager |> delete(behaviour), attributes}

  defp handle_exit_result({:error, reason}, _entity_id, _manager, behaviour),
  do: raise "Error in behaviour #{inspect behaviour} because of: #{inspect reason}"

  defp handle_exit_result(return, _entity_id, _manager, _behaviour),
  do: raise "Return was incorrect. Check the API documentation for behaviours. Got: #{inspect return}"
end
