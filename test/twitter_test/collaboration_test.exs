defmodule TwitterTest.CollaborationTest do
  use ExUnit.Case, async: true
  alias Twitter
  alias TwitterWall.Tweets
  alias TwitterWall.Tweet
  import TwitterAPIMocker

  @tweet_base_url Application.fetch_env!(:twitter_wall, :tweet_base_url)

  describe "Twitter should" do
    test "request user timeline for 3 tweets on call for 3 posted tweets" do
      mock_user_timeline_request(&send(self(), {:user_timeline, &1.query.count}))

      Twitter.posted_tweets(3)

      assert_received {:user_timeline, 3}
    end

    test "request 3 favourite tweets on call for 3 liked tweets" do
      mock_favorites_list_request(&send(self(), {:favorites_list, &1.query.count}))

      Twitter.liked_tweets(3)

      assert_received {:favorites_list, 3}
    end

    test "request 3 oembed htmls on call for htmlize 3 tweets" do
      mock_oembed_request(&send(self(), {:htmlize_tweets, &1.query.url}))

      Twitter.htmlize_tweets(Tweets.new([%Tweet{id: 1}, %Tweet{id: 2}, %Tweet{id: 3}]))

      assert_received {:htmlize_tweets, "#{@tweet_base_url}/1"}
      assert_received {:htmlize_tweets, "#{@tweet_base_url}/2"}
      assert_received {:htmlize_tweets, "#{@tweet_base_url}/3"}
    end
  end
end
