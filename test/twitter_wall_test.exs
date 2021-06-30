defmodule TwitterWallTest do
  use ExUnit.Case, async: true

  import Builders
  import Stubs

  alias TwitterWall.Boundary.Cache
  alias TwitterWall.Config
  alias TwitterWall.Utility.URIBuilder

  @tweet_base_uri "http://twitter.com/base"

  setup [:default_stubs]

  @moduletag cached_aggregate_ttl: 1_000

  setup tags do
    Config.set(:process, tweet_base_uri: @tweet_base_uri)

    cache_server = :test_cache
    start_supervised!({Cache, cached_aggregate_ttl: tags.cached_aggregate_ttl, name: cache_server})

    {:ok, cache_server: cache_server}
  end

  describe "TwitterWall context for happy path should" do
    test "request 3 liked and 3 posted tweets given count 3", %{cache_server: cache_server} do
      me = self()

      stub_liked_tweets_api(fn args ->
        send(me, {:liked_tweets_were_requested, args[:count]})
        {:ok, []}
      end)

      stub_posted_tweets_api(fn args ->
        send(me, {:posted_tweets_were_requested, args[:count]})
        {:ok, []}
      end)

      TwitterWallImpl.get_tweets(3, cache_server)

      assert_receive {:liked_tweets_were_requested, 3}
      assert_receive {:posted_tweets_were_requested, 3}
    end

    test "request html representation for received tweets", %{cache_server: cache_server} do
      stub_liked_tweets_api({:ok, [build_twitter_api_tweet(id: 15)]})
      stub_posted_tweets_api({:ok, [build_twitter_api_tweet(id: 16)]})

      me = self()

      stub_tweet_html_api(fn args ->
        send(me, {:tweet_html_was_requested, args[:url]})
        {:ok, ""}
      end)

      TwitterWallImpl.get_tweets(3, cache_server)

      tweet_url_15 = tweet_url(15)
      tweet_url_16 = tweet_url(16)
      assert_receive {:tweet_html_was_requested, ^tweet_url_15}
      assert_receive {:tweet_html_was_requested, ^tweet_url_16}
    end

    test "return aggregated tweets with date, html, and classified by kind receiving liked and posted tweets from api", %{cache_server: cache_server} do
      stub_liked_tweets_api({:ok, [build_twitter_api_tweet(id: 15, created_at: "Fri Jun 19 17:47:51 +0000 2021")]})
      stub_posted_tweets_api({:ok, [build_twitter_api_tweet(id: 16, created_at: "Fri Jun 01 10:07:21 +0000 2021")]})
      stub_tweet_html_api(fn arg -> {:ok, take_last_path_element(arg[:url])} end)

      tweet_aggregate = TwitterWallImpl.get_tweets(3, cache_server)
      tweets = tweet_aggregate.tweets

      assert Enum.count(tweets) == 2
      tweet_15 = Enum.find(tweets, &(&1.id == 15))
      tweet_16 = Enum.find(tweets, &(&1.id == 16))
      assert tweet_15 == build_tweet(id: 15, date: ~U[2021-06-19 17:47:51Z], html: "15", kind: :liked)
      assert tweet_16 == build_tweet(id: 16, date: ~U[2021-06-01 10:07:21Z], html: "16", kind: :posted)
    end

    test "return first 3 aggregated tweets ordered by descending date given count 3", %{cache_server: cache_server} do
      liked = [
        build_twitter_api_tweet(id: 15, created_at: "Fri Jun 19 17:47:51 +0000 2021"),
        build_twitter_api_tweet(id: 16, created_at: "Fri Jun 19 18:48:31 +0000 2021"),
        build_twitter_api_tweet(id: 18, created_at: "Fri Jun 21 15:30:21 +0000 2021")
      ]

      posted = [
        build_twitter_api_tweet(id: 17, created_at: "Fri Jun 20 10:07:21 +0000 2021"),
        build_twitter_api_tweet(id: 19, created_at: "Fri Jun 22 11:08:41 +0000 2021")
      ]

      stub_liked_tweets_api({:ok, liked})
      stub_posted_tweets_api({:ok, posted})
      stub_tweet_html_api(fn arg -> {:ok, take_last_path_element(arg[:url])} end)

      tweet_aggregate = TwitterWallImpl.get_tweets(3, cache_server)

      assert [%{id: 19}, %{id: 18}, %{id: 17}] = tweet_aggregate.tweets
    end
  end

  describe "TwitterWall context for failures should" do
    test "return aggregated errors giving failed requests for liked or posted tweets", %{cache_server: cache_server} do
      stub_liked_tweets_api({:ok, [build_twitter_api_tweet(id: 15)]})
      stub_posted_tweets_api({:error, %{status: 500}})
      stub_tweet_html_api(fn arg -> {:ok, take_last_path_element(arg[:url])} end)

      tweet_aggregate = TwitterWallImpl.get_tweets(3, cache_server)

      assert [%{id: 15}] = tweet_aggregate.tweets
      assert [%{status: 500}] = tweet_aggregate.errors

      stub_liked_tweets_api({:error, %{reason: :econnrefused}})
      stub_posted_tweets_api({:ok, [build_twitter_api_tweet(id: 16)]})
      stub_tweet_html_api(fn arg -> {:ok, take_last_path_element(arg[:url])} end)

      tweet_aggregate = TwitterWallImpl.get_tweets(3, cache_server)

      assert [%{id: 16}] = tweet_aggregate.tweets
      assert [%{reason: :econnrefused}] = tweet_aggregate.errors
    end

    test "return aggregated errors from all stages giving failed request liked tweets and for tweet html", %{cache_server: cache_server} do
      stub_liked_tweets_api({:error, %{status: 401}})

      stub_posted_tweets_api(
        {:ok, [build_twitter_api_tweet(id: 15), build_twitter_api_tweet(id: 16), build_twitter_api_tweet(id: 17), build_twitter_api_tweet(id: 18)]}
      )

      stub_tweet_html_api(fn arg ->
        element = take_last_path_element(arg[:url])

        if element in ["15", "18"] do
          {:error, %{status: 500, element: element}}
        else
          {:ok, element}
        end
      end)

      tweet_aggregate = TwitterWallImpl.get_tweets(3, cache_server)

      assert [%{id: 16}, %{id: 17}] = tweet_aggregate.tweets
      assert [%{status: 401}, %{status: 500, element: "15"}] = tweet_aggregate.errors
    end
  end

  describe "TwitterWall context for caching should" do
    @describetag liked_tweets_response: {:ok, [build_twitter_api_tweet(id: 15)]}

    setup tags do
      me = self()

      stub_liked_tweets_api(fn _args ->
        send(me, {:liked_tweets_were_requested, Application.get_env(:twitter_wall_test, :api_response_id)})
        tags.liked_tweets_response
      end)

      stub_posted_tweets_api(fn _args ->
        send(me, {:posted_tweets_were_requested, Application.get_env(:twitter_wall_test, :api_response_id)})
        {:ok, [build_twitter_api_tweet(id: 16)]}
      end)

      stub_tweet_html_api(fn arg ->
        send(me, {:tweet_htmls_were_requested, Application.get_env(:twitter_wall_test, :api_response_id)})
        {:ok, take_last_path_element(arg[:url])}
      end)

      :ok
    end

    test "take aggregated tweets from cache on second request", %{cache_server: cache_server} do
      Application.put_env(:twitter_wall_test, :api_response_id, 1)

      TwitterWallImpl.get_tweets(3, cache_server)

      assert_receive {:liked_tweets_were_requested, 1}
      assert_receive {:posted_tweets_were_requested, 1}
      assert_receive {:tweet_htmls_were_requested, 1}

      Application.put_env(:twitter_wall_test, :api_response_id, 2)

      TwitterWallImpl.get_tweets(3, cache_server)

      refute_receive {:liked_tweets_were_requested, 2}
      refute_receive {:posted_tweets_were_requested, 2}
      refute_receive {:tweet_htmls_were_requested, 2}
    after
      Application.delete_env(:twitter_wall_test, :api_response_id)
    end

    @tag liked_tweets_response: {:error, %{status: 500}}
    test "Not cache tweets giving failed api requests", %{cache_server: cache_server} do
      Application.put_env(:twitter_wall_test, :api_response_id, 1)

      TwitterWallImpl.get_tweets(3, cache_server)

      assert_receive {:liked_tweets_were_requested, 1}
      assert_receive {:posted_tweets_were_requested, 1}
      assert_receive {:tweet_htmls_were_requested, 1}

      Application.put_env(:twitter_wall_test, :api_response_id, 2)

      TwitterWallImpl.get_tweets(3, cache_server)

      assert_receive {:liked_tweets_were_requested, 2}
      assert_receive {:posted_tweets_were_requested, 2}
      assert_receive {:tweet_htmls_were_requested, 2}
    after
      Application.delete_env(:twitter_wall_test, :api_response_id)
    end

    @tag cached_aggregate_ttl: 100
    test "request tweets from api again having having wall time greater then cache expiration time", %{cache_server: cache_server} do
      Application.put_env(:twitter_wall_test, :api_response_id, 1)

      TwitterWallImpl.get_tweets(3, cache_server)

      assert_receive {:liked_tweets_were_requested, 1}
      assert_receive {:posted_tweets_were_requested, 1}
      assert_receive {:tweet_htmls_were_requested, 1}

      Process.sleep(150)

      Application.put_env(:twitter_wall_test, :api_response_id, 2)

      TwitterWallImpl.get_tweets(3, cache_server)

      assert_receive {:liked_tweets_were_requested, 2}
      assert_receive {:posted_tweets_were_requested, 2}
      assert_receive {:tweet_htmls_were_requested, 2}
    after
      Application.delete_env(:twitter_wall_test, :api_response_id)
    end
  end

  defp tweet_url(tweet_id) do
    URIBuilder.uri_string_by_appending_path(@tweet_base_uri, to_string(tweet_id))
  end

  defp take_last_path_element(url) do
    ~r|\/([^\/]+)$|
    |> Regex.scan(url, capture: :all_but_first)
    |> List.flatten()
    |> List.first()
  end
end
