defmodule TwitterWall.CachedWall do
  @moduledoc """
  Am implementation of twitter wall getting tweets from cache
  or falling back to requesting from web.

  Module decorates web implementation of twitter wall.
  """
  alias TwitterWall.Infra.CacheService
  alias TwitterWall.Infra.OnlineWallService

  @cache_time Application.fetch_env!(:twitter_wall, :cached_html_validity_ms)

  @behaviour TwitterWall

  @impl true
  def last_liked_or_posted(count, opts \\ []) do
    now = opts[:now] || DateTime.utc_now()

    case !opts[:reset_cache] and CacheService.htmls(count, valid_on: now) do
      {:hit, htmls} ->
        {:ok, htmls}

      _ ->
        with {:ok, htmls} <- OnlineWallService.last_liked_or_posted(count) do
          CacheService.put(htmls, count, expire_on: DateTime.add(now, @cache_time, :millisecond))
          {:ok, htmls}
        end
    end
  end
end
