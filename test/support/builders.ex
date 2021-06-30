defmodule Builders do
  @moduledoc false

  import ExternalResource

  alias TwitterWall.Core.Tweet
  alias TwitterWall.Core.TweetAggregate

  @liked_tweets_list decode_external_json("test/api_responses/favorites_list_success.json", keys: :atoms)

  def build_twitter_api_tweet(fields \\ []) do
    tweet_map = List.first(@liked_tweets_list)

    Enum.reduce(fields, tweet_map, fn {key, value}, map ->
      Map.replace!(map, key, value)
    end)
  end

  def build_tweet_aggregate(fields \\ []) do
    fields
    |> tweet_aggregate_fields()
    |> TweetAggregate.new()
  end

  def tweet_aggregate_fields(fields \\ []) do
    Keyword.merge(
      [
        tweets: [build_tweet()],
        errors: []
      ],
      fields
    )
  end

  def build_tweet(fields \\ []) do
    fields
    |> tweet_fields()
    |> Tweet.new()
  end

  def tweet_fields(fields \\ []) do
    Keyword.merge(
      [
        id: "1",
        date: ~D[2021-06-28],
        html: "This a tweet",
        kind: :liked
      ],
      fields
    )
  end
end
