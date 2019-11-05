defmodule TwitterTest.ErrorContractTest do
  use ExUnit.Case, async: true
  alias Twitter
  alias TwitterWall.Tweets
  alias TwitterWall.Tweet
  import TwitterAPIMocker

  @tweet_base_uri Application.fetch_env!(:twitter_wall, :tweet_base_url)

  describe "Twitter should" do
    test "return backend error metadata on liked tweets request failure" do
      mock_favorites_list_request(fn _ -> {500, "down"} end)

      error =
        Twitter.liked_tweets(3)
        |> Tweets.errors()
        |> List.first()

      assert error == {Twitter, :liked_tweets, %Tesla.Env{status: 500, body: "down"}}
    end

    test "return backend error metadata on posted tweets request failure" do
      mock_user_timeline_request(fn _ -> {500, "down"} end)

      error =
        Twitter.posted_tweets(3)
        |> Tweets.errors()
        |> List.first()

      assert error == {Twitter, :posted_tweets, %Tesla.Env{status: 500, body: "down"}}
    end

    test "return backend error metadata on oembed request failure for tweets htmlize" do
      mock_oembed_requests(%{"#{@tweet_base_uri}/456" => fn _ -> {501, "down"} end})

      error =
        Twitter.htmlize_tweets(Tweets.new([%Tweet{id: 456}]))
        |> Tweets.errors()
        |> List.first()

      assert error == {Twitter, :htmlize_tweets, %Tesla.Env{status: 501, body: "down"}}
    end

    test "return either tweets with html and errors according to oembed requests result on tweets htmlize" do
      mock_oembed_requests(%{
        "#{@tweet_base_uri}/123" => fn _ -> %{html: "1"} end,
        "#{@tweet_base_uri}/245" => fn _ -> %{html: "2"} end,
        "#{@tweet_base_uri}/456" => fn _ -> {501, "down"} end
      })

      tweets =
        Twitter.htmlize_tweets(Tweets.new([%Tweet{id: 123}, %Tweet{id: 245}, %Tweet{id: 456}]))

      assert tweets ==
               Tweets.new(
                 [
                   %Tweet{id: 123, html: "1"},
                   %Tweet{id: 245, html: "2"}
                 ],
                 [
                   {Twitter, :htmlize_tweets, %Tesla.Env{status: 501, body: "down"}}
                 ]
               )
    end
  end
end
