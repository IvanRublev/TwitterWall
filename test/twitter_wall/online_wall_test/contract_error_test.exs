defmodule TwitterWallWeb.OnlineWallTest.ContractErrorTest do
  use ExUnit.Case, async: true
  import Mox
  alias TwitterWall.OnlineWall
  alias TwitterWall.Infra.TwitterService
  alias TwitterWall.Tweets
  alias TwitterWall.Tweet

  describe "OnlineWall should return" do
    test ":error and joined list of errors when liked and posted tweet requests failed" do
      TwitterService.Double
      |> stub(:liked_tweets, fn _ ->
        %Tweets{errors: [{TwitterService, :liked_tweets, :err404}]}
      end)
      |> stub(:posted_tweets, fn _ ->
        %Tweets{errors: [{TwitterService, :posted_tweets, :err500}]}
      end)

      assert OnlineWall.last_liked_or_posted(3) ==
               {:error,
                [
                  {TwitterService, :liked_tweets, :err404},
                  {TwitterService, :posted_tweets, :err500}
                ]}
    end

    test ":error and list of errors when failed to htmlize requested tweets" do
      TwitterService.Double
      |> stub(:liked_tweets, fn _ -> Tweets.new([%Tweet{id: "1"}]) end)
      |> stub(:posted_tweets, fn _ -> Tweets.new([%Tweet{id: "2"}]) end)
      |> stub(:htmlize_tweets, fn _ ->
        %Tweets{
          errors: [
            {TwitterService, :htmlize_tweets, :err501},
            {TwitterService, :htmlize_tweets, :err501}
          ]
        }
      end)

      assert(
        OnlineWall.last_liked_or_posted(3) ==
          {:error,
           [
             {TwitterService, :htmlize_tweets, :err501},
             {TwitterService, :htmlize_tweets, :err501}
           ]}
      )
    end

    test ":ok and htmlized tweets when failed to htmlize only part of them" do
      TwitterService.Double
      |> stub(:liked_tweets, fn _ -> Tweets.new([%Tweet{id: "1"}]) end)
      |> stub(:posted_tweets, fn _ -> Tweets.new([%Tweet{id: "2"}]) end)
      |> stub(:htmlize_tweets, fn _ ->
        %Tweets{
          all: [%Tweet{id: 2, html: "content"}],
          errors: [{TwitterService, :htmlize_tweets, :err501}]
        }
      end)

      assert(OnlineWall.last_liked_or_posted(3) == {:ok, ["content"]})
    end
  end
end
