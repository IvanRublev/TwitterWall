defmodule TwitterWall.Infra.TwitterService.Stub do
  @moduledoc """
  An implementation of Twitter interface to stubbing tweets.
  """
  alias TwitterWall.Infra.TwitterService
  alias TwitterWall.Tweets
  alias TwitterWall.Tweet

  @behaviour TwitterService

  @impl true
  def liked_tweets(count), do: rand_tweets(count)

  @impl true
  def posted_tweets(count), do: rand_tweets(count)

  defp rand_tweets(count) do
    Tweets.new(Enum.map(1..count, &%Tweet{html: "tw#{&1}"}))
  end

  @impl true
  def htmlize_tweets(%Tweets{} = tweets) do
    tweets.all
    |> Enum.with_index()
    |> Enum.map(&%Tweet{elem(&1, 0) | html: "tw#{elem(&1, 1)}"})
    |> Tweets.new()
  end
end
