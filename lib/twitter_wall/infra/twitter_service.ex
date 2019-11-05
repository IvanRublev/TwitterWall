defmodule TwitterWall.Infra.TwitterService do
  @moduledoc """
  A behaviour module for implementing interface for Twitter service data structures.
  """
  use Knigge, otp_app: :twitter_wall

  alias TwitterWall.Tweets

  @callback liked_tweets(count :: non_neg_integer) :: Tweets.t()
  @callback posted_tweets(count :: non_neg_integer) :: Tweets.t()
  @callback htmlize_tweets(tweets :: Tweets.t()) :: Tweets.t()
end
