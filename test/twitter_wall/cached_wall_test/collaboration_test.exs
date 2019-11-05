defmodule TwitterWall.CachedWallTest.CollaborationTest do
  use ExUnit.Case, async: true
  import Mox
  alias TwitterWall.Infra.CacheService
  alias TwitterWall.CachedWall
  alias TwitterWall.Infra.OnlineWallService

  @cache_time Application.fetch_env!(:twitter_wall, :cached_html_validity_ms)

  describe "CachedWall should" do
    test "call cache for 3 htmls valid now when 3 are requested" do
      stub(CacheService.Double, :put, fn _, _, expire_on: _ -> :ok end)

      expect(CacheService.Double, :htmls, 1, fn count, valid_on: date ->
        send(self(), {:htmls, count, date})
        {:empty}
      end)

      stub(OnlineWallService.Double, :last_liked_or_posted, fn _ -> {:ok, ["1", "2"]} end)

      CachedWall.last_liked_or_posted(3, now: ~U[2019-09-20 01:18:35Z])

      assert Mox.verify!(CacheService.Double)
      assert_received {:htmls, 3, ~U[2019-09-20 01:18:35Z]}
    end

    for cache_status <- [:empty, :count_mismatch, :expired] do
      test "call online source for 3 tweets on #{cache_status} from cache when 3 are requested" do
        stub_with(CacheService.Double, CacheService.Stub)

        stub(CacheService.Double, :htmls, fn _, valid_on: _ -> {unquote(cache_status)} end)

        expect(OnlineWallService.Double, :last_liked_or_posted, 1, fn count ->
          send(self(), {:last_liked_or_posted, count})
          {:ok, ["1", "2"]}
        end)

        CachedWall.last_liked_or_posted(3, now: ~U[2019-09-20 01:18:35Z])

        assert Mox.verify!(OnlineWallService.Double)
        assert_received {:last_liked_or_posted, 3}
      end

      test "update cache with htmls from online source on #{cache_status} from cache when 3 tweets are requested" do
        stub(CacheService.Double, :htmls, fn _, valid_on: _ -> {unquote(cache_status)} end)

        stub(OnlineWallService.Double, :last_liked_or_posted, fn _ -> {:ok, ["1", "2"]} end)

        expect(CacheService.Double, :put, 1, fn htmls, count, expire_on: exp_date ->
          duration = DateTime.diff(exp_date, ~U[2019-09-20 01:18:35Z], :millisecond)
          send(self(), {:put, htmls, count, duration})
          :ok
        end)

        CachedWall.last_liked_or_posted(3, now: ~U[2019-09-20 01:18:35Z])

        assert Mox.verify!(OnlineWallService.Double)
        assert_received {:put, ["1", "2"], 3, @cache_time}
      end
    end

    test "update valid cache with htmls from online source when reset_cache: true option is given and 3 tweets are requested" do
      stub(CacheService.Double, :htmls, fn _, valid_on: _ -> {:hit, []} end)

      stub(OnlineWallService.Double, :last_liked_or_posted, fn _ -> {:ok, ["1", "2"]} end)

      expect(CacheService.Double, :put, 1, fn htmls, count, expire_on: exp_date ->
        duration = DateTime.diff(exp_date, ~U[2019-09-20 01:18:35Z], :millisecond)
        send(self(), {:put, htmls, count, duration})
        :ok
      end)

      CachedWall.last_liked_or_posted(3, now: ~U[2019-09-20 01:18:35Z], reset_cache: true)

      assert Mox.verify!(OnlineWallService.Double)
      assert_received {:put, ["1", "2"], 3, @cache_time}
    end
  end
end
