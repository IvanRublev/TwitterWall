defmodule TwitterWallWeb.TweetController do
  use TwitterWallWeb, :controller

  @tweet_count Application.fetch_env!(:twitter_wall, :twitter_wall_tweets_count)

  def index(conn, _params) do
    conn =
      case TwitterWall.last_liked_or_posted(@tweet_count) do
        {:ok, htmls} ->
          conn
          |> assign(:tweets_html, htmls)
          |> assign(:include_twitter_js, true)
          |> assign(:general_error, false)

        {:error, _} ->
          conn
          |> assign(:tweets_html, "")
          |> assign(:include_twitter_js, false)
          |> assign(:general_error, true)
      end

    render(conn, "index.html")
  end
end
