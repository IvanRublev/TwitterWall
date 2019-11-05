defmodule TwitterWall.CachedWallTest.ContractTest do
  use ExUnit.Case, async: true
  import Mox
  alias TwitterWall.Infra.CacheService
  alias TwitterWall.CachedWall
  alias TwitterWall.Infra.OnlineWallService

  describe "CachedWall should" do
    setup do
      stub_with(CacheService.Double, CacheService.Stub)
      :ok
    end

    test "return :ok and 3 htmls from cache on hit when 3 are requested" do
      stub(CacheService.Double, :htmls, fn _, valid_on: _ -> {:hit, ["1", "2", "3"]} end)

      {status, htmls} = CachedWall.last_liked_or_posted(3)

      assert status == :ok
      assert htmls == ["1", "2", "3"]
    end

    test "return :ok and 3 htmls from online source when cache is populated and :reset_cache true option is given" do
      stub(CacheService.Double, :htmls, fn _, valid_on: _ -> {:hit, ["1", "2", "3"]} end)

      stub(OnlineWallService.Double, :last_liked_or_posted, fn _ ->
        {:ok, ["4", "5"]}
      end)

      {status, htmls} = CachedWall.last_liked_or_posted(3, reset_cache: true)

      assert status == :ok
      assert htmls == ["4", "5"]
    end

    for cache_status <- [:empty, :count_mismatch, :expired] do
      test "bypass tweets response from twitter wall's online source on #{cache_status} from cache when 3 are requested" do
        stub(CacheService.Double, :htmls, fn _, valid_on: _ -> {unquote(cache_status)} end)

        stub(OnlineWallService.Double, :last_liked_or_posted, fn _ ->
          {:ok, ["1", "2"]}
        end)

        {status, htmls} = CachedWall.last_liked_or_posted(3)

        assert status == :ok
        assert htmls == ["1", "2"]
      end
    end
  end
end
