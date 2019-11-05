defmodule TwitterWallWeb.OnlineWall.ContractOkTest do
  use ExUnit.Case, async: true
  import Mox
  alias TwitterWall.OnlineWall
  alias TwitterWall.Infra.TwitterService
  alias TwitterWall.Tweets
  alias TwitterWall.Tweet

  describe "OnlineWall should return :ok and" do
    test "0 tweet htmls when none are requested" do
      stub_with(TwitterService.Double, TwitterService.Stub)

      assert OnlineWall.last_liked_or_posted(0) == {:ok, []}
    end

    test "3 tweet htmls when requested" do
      stub_with(TwitterService.Double, TwitterService.Stub)

      {status, htmls} = OnlineWall.last_liked_or_posted(3)

      assert status == :ok
      assert length(htmls) == 3
    end

    test "15 tweet htmls when requested" do
      stub_with(TwitterService.Double, TwitterService.Stub)

      {status, htmls} = OnlineWall.last_liked_or_posted(15)

      assert status == :ok
      assert length(htmls) == 15
    end

    test "3 most recent tweet htmls from liked and posted mix sorted by date" do
      [tw1, tw2, tw3, tw4, tw5, tw6] = [
        %Tweet{date: ~D[2019-09-03], html: "1"},
        %Tweet{date: ~D[2019-10-12], html: "2"},
        %Tweet{date: ~D[2019-09-01], html: "3"},
        %Tweet{date: ~D[2019-09-15], html: "4"},
        %Tweet{date: ~D[2019-10-08], html: "5"},
        %Tweet{date: ~D[2019-10-20], html: "6"}
      ]

      TwitterService.Double
      |> stub(:liked_tweets, fn _ -> Tweets.new([tw1, tw2, tw3]) end)
      |> stub(:posted_tweets, fn _ -> Tweets.new([tw4, tw5, tw6]) end)
      |> stub(:htmlize_tweets, fn tw -> tw end)

      assert OnlineWall.last_liked_or_posted(3) == {:ok, ["6", "2", "5"]}
    end

    test "only unique htmls from union of liked and posted tweets" do
      [tw1, tw2, tw3, tw4, tw5, tw6] = [
        %Tweet{date: ~D[2019-09-03], html: "1"},
        %Tweet{date: ~D[2019-10-12], html: "2"},
        %Tweet{date: ~D[2019-09-01], html: "3"},
        %Tweet{date: ~D[2019-09-15], html: "4"},
        %Tweet{date: ~D[2019-10-08], html: "5"},
        %Tweet{date: ~D[2019-10-20], html: "6"}
      ]

      TwitterService.Double
      |> stub(:liked_tweets, fn _ -> Tweets.new([tw1, tw6, tw2, tw5, tw3]) end)
      |> stub(:posted_tweets, fn _ -> Tweets.new([tw4, tw5, tw2, tw6]) end)
      |> stub(:htmlize_tweets, fn tw -> tw end)

      assert OnlineWall.last_liked_or_posted(3) == {:ok, ["6", "2", "5"]}
    end

    test "0 htmls when no liked or posted tweets are on the service" do
      TwitterService.Double
      |> stub(:liked_tweets, fn _ -> %Tweets{} end)
      |> stub(:posted_tweets, fn _ -> %Tweets{} end)
      |> stub(:htmlize_tweets, fn tw -> tw end)

      assert OnlineWall.last_liked_or_posted(3) == {:ok, []}
    end

    test "1 html when requested 3 tweets and having only one liked on the service" do
      TwitterService.Double
      |> stub(:liked_tweets, fn _ -> Tweets.new([%Tweet{html: "1"}]) end)
      |> stub(:posted_tweets, fn _ -> %Tweets{} end)
      |> stub(:htmlize_tweets, fn tw -> tw end)

      assert OnlineWall.last_liked_or_posted(3) == {:ok, ["1"]}
    end
  end
end
