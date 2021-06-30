defmodule TwitterWallWeb.FeedLiveTest do
  use TwitterWallWeb.ConnCase, async: true

  import Builders
  import HtmlGetters
  import Phoenix.LiveViewTest
  import Stubs

  @moduletag tweet_limit: nil
  @moduletag errors: []

  setup [:default_stubs]

  setup context do
    stub_wall_get_tweets(fn arg ->
      tweets = Enum.map(1..(context.tweet_limit || arg[:count]), &build_tweet(html: "tweet#{&1}"))
      build_tweet_aggregate(tweets: tweets, errors: context.errors)
    end)

    conn = Plug.Test.init_test_session(context.conn, config: [screen_name: "screen_name", default_tweet_count: 3])
    {:ok, view, html} = live(conn, "/")

    {:ok, view: view, html: html}
  end

  describe "Feed Live view should" do
    test "include twitter oembed library to render tweets on client", %{html: html} do
      assert html =~ "<script>window.twttr = (function(d, s, id)"
    end

    test "show link to twitter account in header", %{html: html} do
      assert get_tag(html, "h1 a") == [{"a", [{"href", "https://twitter.com/screen_name"}], ["screen_name"]}]
    end

    test "display 3 tweets by default", %{view: view} do
      assert view
             |> element("input[name='count']")
             |> render()
             |> get_attribute("value") == ["3"]

      assert view
             |> element("div#feed")
             |> render()
             |> get_child_texts() == ["tweet1", "tweet2", "tweet3"]
    end

    test "display appropriate number of tweets giving bigger number in input field", %{view: view} do
      view
      |> element("form")
      |> render_change(%{count: 4})

      assert view
             |> render()
             |> get_child_texts("div#feed") == ["tweet1", "tweet2", "tweet3", "tweet4"]

      view
      |> element("form")
      |> render_change(%{count: 5})

      assert view
             |> render()
             |> get_child_texts("div#feed") == ["tweet1", "tweet2", "tweet3", "tweet4", "tweet5"]
    end
  end

  describe "Feed Live view for errors should" do
    test "display input value error message with no tweets giving not a number value for count input", %{view: view} do
      html =
        view
        |> element("form")
        |> render_change(%{count: "hello world"})

      assert get_child_texts(html, "dev#feed") == []
      assert [{"p", _, ["Count should be an integer in the 1..10 range. Given value is \"hello world\"."]}] = get_tag(html, "p#error")
    end

    test "display input value error message giving a number value out of 1..10 range", %{view: view} do
      html =
        view
        |> element("form")
        |> render_change(%{count: "568"})

      assert get_child_texts(html, "dev#feed") == []
      assert [{"p", _, ["Count should be an integer in the 1..10 range. Given value is 568."]}] = get_tag(html, "p#error")
    end

    @tag tweet_limit: 2, errors: [%{status: 500}]
    test "display available tweets and twitter is fuzzy error message giving twitter api failure", %{view: view} do
      assert view
             |> element("div#feed")
             |> render()
             |> get_child_texts() == ["tweet1", "tweet2"]

      error_html =
        view
        |> element("p#error")
        |> render()

      assert [{"p", _, ["Output is limited. Connection to Twitter is Fuzzy today 🤪"]}] = get_tag(error_html, "p#error")
    end
  end
end
