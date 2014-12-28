# defmodule Entice.Cynosure.World.Supervisor do
#   use Supervisor
#   alias Entice.Cynosure.World

#   def start_link(map_name, map_data) do
#     Supervisor.start_link(__MODULE__, {map_name, map_data})
#   end

#   @event_manager_name Entice.Cynosure.World.EventManager
#   @world_name KV.Registry
#   @bucket_sup_name KV.Bucket.Supervisor


#   def init({map_name, map_data}) do
#     children = [
#       worker(GenEvent, [[name: @manager_name]]),
#       supervisor(KV.Bucket.Supervisor, [[name: @bucket_sup_name]]),
#       worker(KV.Registry, [@manager_name, @bucket_sup_name, [name: @registry_name]])
#       worker(World, [map_name, map_data])
#     ]
#     supervise(children, strategy: :one_for_one)
#   end
# end
