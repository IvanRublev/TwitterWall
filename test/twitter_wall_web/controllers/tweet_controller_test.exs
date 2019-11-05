defmodule TwitterWallWeb.TweetControllerTest do
  use TwitterWallWeb.ConnCase, async: true
  import Mox

  describe "GET / response should" do
    setup %{conn: conn} do
      stub_with(TwitterWall.Double, TwitterWall.Stub)
      {:ok, conn: get(conn, "/")}
    end

    test "have status 200", %{conn: conn} do
      assert html_response(conn, 200)
    end

    test "include twitter oembed library", %{conn: conn} do
      assert html_response(conn) =~ "<script>window.twttr = (function(d, s, id)"
    end

    test "contain three tweets as blockquotes", %{conn: conn} do
      assert html_response(conn) =~ "<blockquote>tweet1</blockquote>"
      assert html_response(conn) =~ "<blockquote>tweet2</blockquote>"
      assert html_response(conn) =~ "<blockquote>tweet3</blockquote>"
    end
  end

  describe "GET / response in case of error from twitter wall should" do
    setup %{conn: conn} do
      TwitterWall.Double
      |> stub(:last_liked_or_posted, fn _ ->
        {:error,
         [
           {TwitterService, :liked_tweets, :err404},
           {TwitterService, :posted_tweets, :err500}
         ]}
      end)

      {:ok, conn: get(conn, "/")}
    end

    test "contain twitter is fuzzy message", %{conn: conn} do
      assert html_response(conn) =~
               "<div>Can't show anything. Connection to Twitter is Fuzzy today 🤪</div>"
    end

    test "do not include twitter oembed library", %{conn: conn} do
      assert !(html_response(conn) =~ "<script>window.twttr = (function(d, s, id)")
    end
  end
end
