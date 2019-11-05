defmodule TwitterTest.CountContractTest do
  use ExUnit.Case, async: true
  alias Twitter
  alias TwitterWall.Tweets
  alias TwitterWall.Tweet
  import TwitterAPIMocker

  @tweet_base_uri Application.fetch_env!(:twitter_wall, :tweet_base_url)

  describe "Twitter should" do
    test "return 3 liked tweets if have them on service" do
      mock_favorites_list_request(fn _ -> [%{id: 1}, %{id: 2}, %{id: 3}] end)

      assert Tweets.count(Twitter.liked_tweets(3)) == 3
    end

    test "return all liked tweets if have less then requested on service" do
      mock_favorites_list_request(fn _ -> [%{id: 1}, %{id: 2}] end)

      assert Tweets.count(Twitter.liked_tweets(3)) == 2
    end

    test "return 0 liked tweets if have no any on service" do
      mock_favorites_list_request(fn _ -> [] end)

      assert Tweets.count(Twitter.liked_tweets(3)) == 0
    end

    test "return 0 liked tweets in case of backend error" do
      mock_favorites_list_request(fn _ -> 500 end)

      assert Tweets.count(Twitter.liked_tweets(3)) == 0
    end

    test "return 3 posted tweets if have them on service" do
      mock_user_timeline_request(fn _ -> [%{id: 1}, %{id: 2}, %{id: 3}] end)

      assert Tweets.count(Twitter.posted_tweets(3)) == 3
    end

    test "return all posted tweets if have less then requested on service" do
      mock_user_timeline_request(fn _ -> [%{id: 1}] end)

      assert Tweets.count(Twitter.posted_tweets(3)) == 1
    end

    test "return 0 posted tweets if have no them on service" do
      mock_user_timeline_request(fn _ -> [] end)

      assert Tweets.count(Twitter.posted_tweets(3)) == 0
    end

    test "return 0 posted tweets in case of backend error" do
      mock_user_timeline_request(fn _ -> 500 end)

      assert Tweets.count(Twitter.posted_tweets(3)) == 0
    end

    test "return 3 tweets when html is provided by service for 3 of them" do
      mock_oembed_request(fn _ -> %{html: "content"} end)

      tweets =
        Tweets.new([
          %Tweet{id: 123},
          %Tweet{id: 345},
          %Tweet{id: 564}
        ])

      assert Tweets.count(Twitter.htmlize_tweets(tweets)) == 3
    end

    test "return all htmlized tweets if received less htmls then requested from service" do
      mock_oembed_requests(%{
        "#{@tweet_base_uri}/123" => fn _ -> %{html: "1"} end,
        "#{@tweet_base_uri}/345" => fn _ -> {501, "down"} end
      })

      tweets =
        Tweets.new([
          %Tweet{id: 123},
          %Tweet{id: 345}
        ])

      assert Tweets.count(Twitter.htmlize_tweets(tweets)) == 1
    end
  end
end
