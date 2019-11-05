defmodule Cache.Heater do
  @moduledoc """
  A module implementing cache heater. That periodically requests tweets
  for twitter wall what consequently fills the cache with tweets.
  """
  require Logger
  use GenServer, restart: :transient

  @tweet_count Application.fetch_env!(:twitter_wall, :twitter_wall_tweets_count)
  @cache_validity Application.fetch_env!(:twitter_wall, :cached_html_validity_ms)
  @timeout round(@cache_validity / 4 * 3)

  def start_link(arg) do
    name = Keyword.get(arg, :name, __MODULE__)
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  ### GenServer
  @impl true
  def init(_arg) do
    heat_cache()

    Logger.debug(
      "#{__MODULE__} initially heated the cache and set reheat timeout to #{@timeout} ms."
    )

    {:ok, nil, @timeout}
  end

  defp heat_cache(), do: TwitterWall.last_liked_or_posted(@tweet_count, reset_cache: true)

  @impl true
  def handle_info(_, state) do
    Logger.debug("#{__MODULE__} heating cache on timeout.")
    heat_cache()
    {:noreply, state, @timeout}
  end
end
