defmodule Entice.Area.Entity.Events do

  def entity_added(area, entity_id) do
    GenEvent.notify(area.Evt, {:entity_added, entity_id})
  end

  def entity_removed(area, entity_id) do
    GenEvent.notify(area.Evt, {:entity_removed, entity_id})
  end

  def attribute_updated(area, entity_id, attribute) do
    GenEvent.notify(area.Evt, {:attribute_updated, entity_id, attribute})
  end

  def attribute_removed(area, entity_id, attribute_type) do
    GenEvent.notify(area.Evt, {:attribute_removed, entity_id, attribute_type})
  end
end
