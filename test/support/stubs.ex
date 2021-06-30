defmodule Stubs do
  @moduledoc false

  import Mox

  alias TwitterWall.Boundary.TwitterAPIMock
  alias TwitterWall.Boundary.TwitterAPIImpl

  def default_stubs(_context) do
    Mox.stub_with(TwitterWallMock, TwitterWallImpl)
    Mox.stub_with(TwitterAPIMock, TwitterAPIImpl)
    :ok
  end

  def stub_wall_get_tweets(reply) do
    stub(TwitterWallMock, :get_tweets, fn count ->
      call_or_bypass(reply, count: count)
    end)
  end

  def stub_liked_tweets_api(reply) do
    stub(TwitterAPIMock, :favorites, fn count ->
      call_or_bypass(reply, count: count)
    end)
  end

  def stub_posted_tweets_api(reply) do
    stub(TwitterAPIMock, :user_timeline, fn count ->
      call_or_bypass(reply, count: count)
    end)
  end

  def stub_tweet_html_api(reply) do
    stub(TwitterAPIMock, :oembed, fn url ->
      call_or_bypass(reply, url: url)
    end)
  end

  defp call_or_bypass(reply, args) when is_function(reply), do: reply.(args)
  defp call_or_bypass(reply, _args), do: reply
end
