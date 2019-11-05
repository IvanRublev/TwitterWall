defmodule Cache do
  @moduledoc """
  Supervisor for Cache
  """
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    Supervisor.init([Cache.Memory, Cache.Heater], strategy: :one_for_one)
  end
end
