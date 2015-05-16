defmodule Entice.Entity.Trigger do
  @moduledoc """
  Enables entities to install triggers into other entities,  which
  are side-effecting anonymous functions that receive the other entities
  state and act based on that. They hould return true or false based
  on whether or not they have been triggered and can be removed.
  (`true` to be removed, `false` to be called again)

  The callback code is assumed to have the following signature:

    (%Entity{} -> true | false)
  """
  alias Entice.Entity
  alias Entice.Entity.Trigger

  defstruct triggers: []


  def register(entity),
  do: Entity.put_behaviour(entity, Trigger.Behaviour, [])


  def unregister(entity),
  do: Entity.remove_behaviour(entity, Trigger.Behaviour)


  def trigger(entity, trigger) when is_function(trigger, 1),
  do: Entity.notify(entity, {:trigger, trigger})


  def trigger_all(trigger) when is_function(trigger, 1),
  do: Entity.notify_all({:trigger, trigger})


  defmodule Behaviour do
    use Entice.Entity.Behaviour
    alias Entice.Entity.Trigger

    def init(entity, _args),
    do: {:ok, entity |> put_attribute(%Trigger{})}

    def handle_event({:trigger, trigger}, %Entity{attributes: %{Trigger => %Trigger{triggers: triggers}}} = entity) do
      case trigger.(entity) do
        false -> {:ok, entity |> put_attribute(%Trigger{triggers: [trigger | triggers]})}
        _     -> {:ok, entity}
      end
    end

    def handle_change(_old_state, %Entity{attributes: %{Trigger => %Trigger{triggers: triggers}}} = entity) do
      triggers
      |> Enum.filter_map(
        fn trigger -> trigger.(entity) end,
        fn trigger -> Entity.update_attribute(self, Trigger,
          fn %Trigger{triggers: triggers} -> triggers -- [trigger] end)
        end)
      :ok
    end
  end
end
