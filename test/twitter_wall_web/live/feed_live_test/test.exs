defmodule TwitterWallWeb.FeedLive.Test do
  use TwitterWallWeb.ConnCase, async: true
  import Mox
  import Phoenix.LiveViewTest

  describe "GET / response should" do
    setup %{conn: conn} do
      stub_with(TwitterWall.Double, TwitterWall.Stub)
      {:ok, conn: get(conn, "/")}
    end

    test "have status 200", %{conn: conn} do
      assert html_response(conn, 200)
    end

    test "contain header with tweets count input field with value of 3", %{conn: conn} do
      assert html_response(conn) =~
               "<input type=text name=\"tw_count\" value=\"3\""
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

    test "have status 200", %{conn: conn} do
      assert html_response(conn, 200)
    end

    test "contain header with tweets count input field", %{conn: conn} do
      assert html_response(conn) =~ "<input type=text name=\"tw_count\""
    end

    test "include twitter oembed library", %{conn: conn} do
      assert html_response(conn) =~ "<script>window.twttr = (function(d, s, id)"
    end

    test "not contatin tweets", %{conn: conn} do
      refute html_response(conn) =~ "<blockquote>tweet1</blockquote>"
    end

    test "contain twitter is fuzzy message", %{conn: conn} do
      assert html_response(conn) =~
               "<div>Can't show anything. Connection to Twitter is Fuzzy today 🤪</div>"
    end
  end

  describe "GET / response in case of invalid input value should" do
    setup %{conn: conn} do
      stub_with(TwitterWall.Double, TwitterWall.Stub)

      {:ok, view, _html} = live(conn, "/")
      {:ok, html: render_change(view, :ch_count, %{"tw_count" => 99_999_999})}
    end

    test "not contatin tweets", %{html: html} do
      refute html =~ "<blockquote>tweet1</blockquote>"
    end

    test "include input error message", %{html: html} do
      assert html =~ "<p class=\"alert alert-danger\""
    end
  end
end
