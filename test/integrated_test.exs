defmodule IntegratedTest do
  use TwitterWallWeb.ConnCase, async: true

  import ExternalResource
  import HtmlGetters
  import Phoenix.LiveViewTest
  import Stubs

  alias Plug.Conn
  alias TwitterWall.Boundary.TwitterAPI.Config, as: APIConfig
  alias TwitterWall.Utility.URIBuilder

  setup [:default_stubs]

  @favorites_reply read_external_file("test/api_responses/favorites_list_success.json")
  @user_timeline_reply read_external_file("test/api_responses/user_timeline_success.json")

  setup do
    bypass = Bypass.open()

    endpoint_url = "http://localhost:#{bypass.port}"

    APIConfig.merge(:global,
      twitter_api_1_1_base: URIBuilder.uri_string_by_appending_path(endpoint_url, "/api_1_1_endpoint"),
      twitter_publish_base: URIBuilder.uri_string_by_appending_path(endpoint_url, "/publish_endpoint")
    )

    Bypass.expect(bypass, "GET", "/api_1_1_endpoint/favorites/list.json", fn conn -> Conn.resp(conn, 200, @favorites_reply) end)
    Bypass.expect(bypass, "GET", "/api_1_1_endpoint/statuses/user_timeline.json", fn conn -> Conn.resp(conn, 200, @user_timeline_reply) end)

    me = self()

    Bypass.expect(bypass, "GET", "/publish_endpoint/oembed", fn conn ->
      params = Conn.fetch_query_params(conn).query_params
      url = params["url"]
      path = URI.parse(url).path
      last_path_component = Path.split(path) |> Enum.reverse() |> List.first()

      send(me, {:tweet_loaded, last_path_component})

      success_reply = File.read!("test/api_responses/#{last_path_component}.json")
      Conn.resp(conn, 200, success_reply)
    end)

    :ok
  end

  test "Twitter wall app shows 3 latest liked and posted tweets ordered by date", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert_receive {:tweet_loaded, "1408820015374159881"}
    assert_receive {:tweet_loaded, "1408453899061764102"}
    assert_receive {:tweet_loaded, "1407343703509843976"}

    Process.sleep(100)

    assert [tweet1, tweet2, tweet3] =
             view
             |> element("div#feed")
             |> render()
             |> get_child_texts()

    assert tweet1 =~ "shares how a small team of engineers"
    assert tweet2 =~ "great idea to get more transparency, to challenge the strategic decisions"
    assert tweet3 =~ "In regards to cycles It may be a point when you return to the list"
  end
end
