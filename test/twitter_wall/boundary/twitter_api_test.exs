defmodule TwitterWall.Boundary.TwitterAPITest do
  use ExUnit.Case, async: true

  import ExternalResource

  alias Plug.Conn
  alias TwitterWall.Boundary.TwitterAPIImpl
  alias TwitterWall.Boundary.TwitterAPI.Config, as: APIConfig
  alias TwitterWall.Config, as: GeneralConfig
  alias TwitterWall.Utility.URIBuilder

  setup do
    bypass = Bypass.open()

    GeneralConfig.set(:process, screen_name: "test_screen_name")

    endpoint_url = "http://localhost:#{bypass.port}"

    APIConfig.set(:process,
      twitter_api_1_1_base: URIBuilder.uri_string_by_appending_path(endpoint_url, "/api_1_1_endpoint"),
      twitter_publish_base: URIBuilder.uri_string_by_appending_path(endpoint_url, "/publish_endpoint"),
      bearer_token: "test_bearer_token",
      oauth_consumer_key: "oauth_consumer_key",
      oauth_consumer_secret: "oauth_consumer_secret",
      oauth_token: "oauth_token",
      oauth_token_secret: "oauth_token_secret"
    )

    {:ok, bypass: bypass}
  end

  describe "favorites/1" do
    @path "/api_1_1_endpoint/favorites/list.json"
    @success_reply read_external_file("test/api_responses/favorites_list_success.json")
    @error_reply read_external_file("test/api_responses/favorites_list_not_found_error.json")

    test "send count of tweets, screen name, and auth header to API", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn ->
        assert Conn.get_req_header(conn, "authorization") == ["Bearer test_bearer_token"]

        params = Conn.fetch_query_params(conn).query_params
        assert params["count"] == "11"
        assert params["screen_name"] == "test_screen_name"

        Conn.resp(conn, 200, @success_reply)
      end)

      TwitterAPIImpl.favorites(11)
    end

    test "returns liked tweets", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn -> Conn.resp(conn, 200, @success_reply) end)
      assert {:ok, [%{id: 1_274_036_183_115_464_704}]} = TwitterAPIImpl.favorites(3)
    end

    test "returns network error if any", %{bypass: bypass} do
      Bypass.down(bypass)
      assert {:error, %{reason: :econnrefused}} = TwitterAPIImpl.favorites(3)
    end

    test "returns service 404 error for not found user name", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn -> Conn.resp(conn, 404, @error_reply) end)
      assert {:error, %{status: 404, body: body}} = TwitterAPIImpl.favorites(3)
      assert body =~ "Sorry, that page does not exist."
    end

    test "returns malformed json error", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn -> Conn.resp(conn, 200, "not_a_json") end)
      assert {:error, %{data: "not_a_json"}} = TwitterAPIImpl.favorites(3)
    end
  end

  describe "user_timeline/1" do
    @path "/api_1_1_endpoint/statuses/user_timeline.json"
    @success_reply read_external_file("test/api_responses/user_timeline_success.json")
    @error_reply read_external_file("test/api_responses/user_timeline_unauthorised_error.json")

    test "send count of tweets, screen name, and OAuth header to API", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn ->
        assert [oauth] = Conn.get_req_header(conn, "authorization")
        assert oauth =~ "OAuth"
        assert oauth =~ "oauth_consumer_key"
        assert oauth =~ "oauth_token"
        assert oauth =~ "oauth_nonce"
        assert oauth =~ "oauth_signature"
        assert oauth =~ "oauth_signature_method=\"HMAC-SHA1\""

        params = Conn.fetch_query_params(conn).query_params
        assert params["count"] == "15"
        assert params["screen_name"] == "test_screen_name"

        Conn.resp(conn, 200, @success_reply)
      end)

      TwitterAPIImpl.user_timeline(15)
    end

    test "returns posted tweets", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn -> Conn.resp(conn, 200, @success_reply) end)

      assert {:ok,
              [
                %{id: 1_408_820_015_374_159_881},
                %{id: 1_408_453_899_061_764_102},
                %{id: 1_407_343_703_509_843_976}
              ]} = TwitterAPIImpl.user_timeline(3)
    end

    test "returns network error if any", %{bypass: bypass} do
      Bypass.down(bypass)
      assert {:error, %{reason: :econnrefused}} = TwitterAPIImpl.user_timeline(3)
    end

    test "returns service 401 error for not found user name", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn -> Conn.resp(conn, 401, @error_reply) end)
      assert {:error, %{status: 401, body: body}} = TwitterAPIImpl.user_timeline(3)
      assert body =~ "Invalid or expired token."
    end

    test "returns malformed json error", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn -> Conn.resp(conn, 200, "not_a_json") end)
      assert {:error, %{data: "not_a_json"}} = TwitterAPIImpl.user_timeline(3)
    end
  end

  describe "oembed" do
    @path "/publish_endpoint/oembed"
    @success_reply read_external_file("test/api_responses/oembed_success.json")
    @error_reply read_external_file("test/api_responses/oembed_not_found_error.html")

    test "send url and omit_script params to API", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn ->
        params = Conn.fetch_query_params(conn).query_params
        assert params["url"] == "http://twitter.com/tweet/url"
        assert params["omit_script"] == "true"

        Conn.resp(conn, 200, @success_reply)
      end)

      TwitterAPIImpl.oembed("http://twitter.com/tweet/url")
    end

    test "returns html representation for given tweet url", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn -> Conn.resp(conn, 200, @success_reply) end)

      assert {:ok, html} = TwitterAPIImpl.oembed("http://twitter.com/tweet/url")
      assert html =~ "<blockquote class=\"twitter-tweet\"><p lang=\"en\" dir=\"ltr\">Lean Coffee"
    end

    test "returns network error if any", %{bypass: bypass} do
      Bypass.down(bypass)
      assert {:error, %{reason: :econnrefused}} = TwitterAPIImpl.oembed("http://twitter.com/tweet/url")
    end

    test "returns service 404 error for not missing tweet", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn -> Conn.resp(conn, 404, @error_reply) end)
      assert {:error, %{status: 404, body: body}} = TwitterAPIImpl.oembed("http://twitter.com/tweet/url")
      assert body =~ "Looks like this page doesn’t exist."
    end

    test "returns malformed json error", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn -> Conn.resp(conn, 200, "not_a_json") end)
      assert {:error, %{data: "not_a_json"}} = TwitterAPIImpl.oembed("http://twitter.com/tweet/url")
    end
  end
end
