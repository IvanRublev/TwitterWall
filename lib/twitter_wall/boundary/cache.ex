defmodule TwitterWall.Boundary.Cache do
  @moduledoc """
  Cache server to keep tweet aggregates
  """

  use GenServer, restart: :transient

  alias TwitterWall.Config

  def start_link(arg) do
    config = Config.get()
    aggregate_ttl = arg[:cached_aggregate_ttl] || Keyword.fetch!(config, :cached_aggregate_ttl)

    name = arg[:name] || __MODULE__

    GenServer.start_link(__MODULE__, aggregate_ttl, name: name)
  end

  def put(server, count, aggregate) do
    GenServer.cast(server, {:put, count, aggregate})
  end

  def get(server, count) do
    GenServer.call(server, {:get, count})
  end

  @impl true
  def init(aggregate_ttl) do
    {:ok, %{aggregate_ttl: aggregate_ttl, cache: %{}}}
  end

  @impl true
  def handle_cast({:put, count, aggregate}, state) do
    expire_on = DateTime.utc_now() |> DateTime.add(state.aggregate_ttl, :millisecond)
    updated_state = %{state | cache: Map.put(state.cache, count, {aggregate, expire_on})}

    {:noreply, updated_state}
  end

  @impl true
  def handle_call({:get, count}, _from, state) do
    case state.cache[count] do
      {aggregate, expire_on} ->
        if DateTime.compare(DateTime.utc_now(), expire_on) == :gt do
          {:reply, nil, state}
        else
          {:reply, aggregate, state}
        end

      nil ->
        {:reply, nil, state}
    end
  end
end
