defmodule TwitterWallWeb.OnlineWallTest.CollaborationTest do
  use ExUnit.Case, async: true
  import Mox
  alias TwitterWall.OnlineWall
  alias TwitterWall.Infra.TwitterService

  describe "OnlineWall should" do
    test "not fetch any tweets when 0 are requested" do
      TwitterService.Double
      |> expect(:liked_tweets, 0, fn _ -> nil end)
      |> expect(:posted_tweets, 0, fn _ -> nil end)

      OnlineWall.last_liked_or_posted(0)

      assert Mox.verify!(TwitterService.Double)
    end

    test "fetch 3 liked tweets from twitter service when 3 are requested" do
      stub_with(TwitterService.Double, TwitterService.Stub)

      expect(TwitterService.Double, :liked_tweets, 1, fn count ->
        send(self(), {:liked_tweets, count})
        TwitterService.Stub.liked_tweets(count)
      end)

      OnlineWall.last_liked_or_posted(3)

      assert Mox.verify!(TwitterService.Double)
      assert_received {:liked_tweets, 3}
    end

    test "fetch 3 posted tweets from twitter service when 3 are requested" do
      stub_with(TwitterService.Double, TwitterService.Stub)

      expect(TwitterService.Double, :posted_tweets, 1, fn count ->
        send(self(), {:posted_tweets, count})
        TwitterService.Stub.liked_tweets(count)
      end)

      OnlineWall.last_liked_or_posted(3)

      assert Mox.verify!(TwitterService.Double)
      assert_received {:posted_tweets, 3}
    end

    test "htmlize 3 tweets when 3 are requested" do
      stub_with(TwitterService.Double, TwitterService.Stub)

      expect(TwitterService.Double, :htmlize_tweets, 1, fn tweets ->
        send(self(), {:htmlize_tweets, length(tweets.all)})
        TwitterService.Stub.htmlize_tweets(tweets)
      end)

      OnlineWall.last_liked_or_posted(3)

      assert Mox.verify!(TwitterService.Double)
      assert_received {:htmlize_tweets, 3}
    end
  end
end
