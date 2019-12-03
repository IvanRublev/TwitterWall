defmodule TwitterWallWeb.FeedLive.InputTest do
  use TwitterWallWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Mox
  alias TwitterWallWeb.FeedLive

  describe "Feed Live View should" do
    setup %{conn: conn} do
      stub_with(TwitterWall.Double, TwitterWall.Stub)
      {:ok, view, _html} = live_isolated(conn, FeedLive)
      {:ok, view: view}
    end

    test "reder previous tweets count on empty input", %{view: view} do
      assert render_change(view, :ch_count, %{"tw_count" => ""}) =~
               "name=\"tw_count\" value=\"3\""
    end

    test "show out of range error on input value < 1", %{view: view} do
      assert render_change(view, :ch_count, %{"tw_count" => -1}) =~
               "Count should be in the 1..10 range."
    end

    test "show out of range error on input value > 10", %{view: view} do
      assert render_change(view, :ch_count, %{"tw_count" => 11}) =~
               "Count should be in the 1..10 range."
    end
  end
end
