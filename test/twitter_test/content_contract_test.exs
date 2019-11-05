defmodule TwitterTest.ContentContractTest do
  use ExUnit.Case, async: true
  alias Twitter
  alias TwitterWall.Tweets
  alias TwitterWall.Tweet
  import TwitterAPIMocker

  @tweet_base_uri Application.fetch_env!(:twitter_wall, :tweet_base_url)

  describe "Twitter should return" do
    test "Tweet with id and date from api json responses for liked tweets" do
      mock_favorites_list_request(fn _ ->
        [%{id: 123, created_at: "Fri Sep 20 01:18:35 +0000 2019"}]
      end)

      tweet = List.first(Twitter.liked_tweets(1).all)

      assert %Tweet{} = tweet
      assert tweet.date != nil
      assert Timex.equal?(tweet.date, ~U[2019-09-20 01:18:35Z])
      assert tweet.id == 123
    end

    test "Tweet with id and date from api json responses for posted tweets" do
      mock_user_timeline_request(fn _ ->
        [%{id: 456, created_at: "Mon Aug 19 05:54:05 +0000 2019"}]
      end)

      tweet = List.first(Twitter.posted_tweets(1).all)

      assert %Tweet{} = tweet
      assert tweet.id == 456
      assert tweet.date != nil
      assert Timex.equal?(tweet.date, ~U[2019-08-19 05:54:05Z])
    end

    test "Tweets with list of html populated Tweet for appropriate ids with html from oembed endpoint" do
      mock_oembed_requests(%{
        "#{@tweet_base_uri}/123" => fn _ -> %{html: "1"} end,
        "#{@tweet_base_uri}/345" => fn _ -> %{html: "2"} end,
        "#{@tweet_base_uri}/564" => fn _ -> %{html: "3"} end
      })

      tweets =
        Twitter.htmlize_tweets(
          Tweets.new([
            %Tweet{id: 123},
            %Tweet{id: 345},
            %Tweet{id: 564}
          ])
        )

      assert %Tweets{} = tweets

      assert tweets.all == [
               %Tweet{id: 123, html: "1"},
               %Tweet{id: 345, html: "2"},
               %Tweet{id: 564, html: "3"}
             ]
    end
  end
end
