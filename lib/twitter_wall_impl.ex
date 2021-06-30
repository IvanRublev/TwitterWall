defmodule TwitterWallImpl do
  @moduledoc """
  Implementation for TwitterWall behaviour
  """

  @behaviour TwitterWall

  alias TwitterWall.Boundary.Cache
  alias TwitterWall.Boundary.CountValidator
  alias TwitterWall.Boundary.TwitterAPI
  alias TwitterWall.Config
  alias TwitterWall.Core.Tweet
  alias TwitterWall.Core.TweetAggregate
  alias TwitterWall.Utility.URIBuilder

  @impl true
  defdelegate validate_count(count_string), to: CountValidator, as: :validate

  @impl true
  def get_tweets(count, cache_server \\ Cache) do
    if aggregate = Cache.get(cache_server, count) do
      aggregate
    else
      aggregate = aggregate_from_api(count)

      if Enum.empty?(aggregate.errors) do
        Cache.put(cache_server, count, aggregate)
      end

      aggregate
    end
  end

  defp aggregate_from_api(count) do
    tasks = [
      Task.async(fn -> aggregate_tweets(:liked, fn -> TwitterAPI.favorites(count) end) end),
      Task.async(fn -> aggregate_tweets(:posted, fn -> TwitterAPI.user_timeline(count) end) end)
    ]

    [liked_aggregate, posted_aggregate] = Task.await_many(tasks)

    tweet_base_uri = Config.get() |> Keyword.fetch!(:tweet_base_uri)

    liked_aggregate
    |> TweetAggregate.concat(posted_aggregate)
    |> TweetAggregate.update_tweets(fn tweets ->
      tweets
      |> Enum.sort_by(& &1.date, {:desc, Date})
      |> Enum.take(count)
    end)
    |> TweetAggregate.update_fields(fn fields ->
      {tweets_html, errors} = add_html_tweet_fields(fields[:tweets], tweet_base_uri)
      [tweets: tweets_html, errors: Enum.concat(fields[:errors], errors)]
    end)
  end

  defp aggregate_tweets(kind, fun) do
    case fun.() do
      {:ok, tweet_maps} ->
        tweets_fields =
          tweet_maps
          |> Enum.map(&map_tweet_fields(&1, kind))
          |> Enum.map(&Map.put(&1, :html, ""))

        tweets = Enum.map(tweets_fields, &Tweet.new/1)
        TweetAggregate.new(tweets: tweets, errors: [])

      {:error, message} ->
        TweetAggregate.new(tweets: [], errors: [message])
    end
  end

  defp map_tweet_fields(tweet_map, kind) do
    id = tweet_map.id
    date = Timex.parse!(tweet_map.created_at, "{WDshort} {Mshort} {D} {h24}:{m}:{s} {Z} {YYYY}")

    %{id: id, date: date, kind: kind}
  end

  defp add_html_tweet_fields(tweets_fields, tweet_base_uri) do
    html_tasks = Enum.map(tweets_fields, &oembed_html_task(&1.id, tweet_base_uri))
    htmls = Task.await_many(html_tasks)

    {fields, errors} =
      tweets_fields
      |> Enum.zip(htmls)
      |> Enum.reduce({[], []}, fn {fields, ok_error_html}, {fields_html, errors} ->
        case ok_error_html do
          {:ok, html} -> {[Map.put(fields, :html, html) | fields_html], errors}
          {:error, message} -> {fields_html, [message | errors]}
        end
      end)

    {Enum.reverse(fields), Enum.reverse(errors)}
  end

  defp oembed_html_task(tweet_id, tweet_base_uri) do
    url = URIBuilder.uri_string_by_appending_path(tweet_base_uri, to_string(tweet_id))
    Task.async(fn -> TwitterAPI.oembed(url) end)
  end
end
