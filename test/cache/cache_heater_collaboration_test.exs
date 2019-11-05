defmodule Cache.HeaterCollaborationTest do
  use ExUnit.Case, async: false
  import Mox

  alias Cache.Heater

  @tweet_count Application.fetch_env!(:twitter_wall, :twitter_wall_tweets_count)

  describe "Heater should" do
    setup ctx do
      set_mox_global()
      {:ok, ctx}
    end

    test "make twitter wall reset cache on start", ctx do
      me = self()

      expect(TwitterWall.Double, :last_liked_or_posted, 1, fn count, opts ->
        send(me, {:last_liked_or_posted, count, opts})
        TwitterWall.Stub.last_liked_or_posted(count)
      end)

      Heater.start_link(name: ctx.test)

      assert Mox.verify!(TwitterWall.Double)
      assert_received {:last_liked_or_posted, @tweet_count, [reset_cache: true]}
    end

    test "specify both initial and after fetch timeouts for cache heating as 3/4 of html validity time" do
      stub_with(TwitterWall.Double, TwitterWall.Stub)

      timeout = 75
      assert Heater.init(nil) == {:ok, nil, timeout}
      assert Heater.handle_info(:timeout, nil) == {:noreply, nil, timeout}
    end

    test "fetch liked or posted tweets from twitter wall on timeout" do
      me = self()

      expect(TwitterWall.Double, :last_liked_or_posted, 1, fn count, opts ->
        send(me, {:last_liked_or_posted, count, opts})
        TwitterWall.Stub.last_liked_or_posted(count)
      end)

      Heater.handle_info(:timeout, nil)

      assert Mox.verify!(TwitterWall.Double)
      assert_received {:last_liked_or_posted, @tweet_count, [reset_cache: true]}
    end
  end
end
