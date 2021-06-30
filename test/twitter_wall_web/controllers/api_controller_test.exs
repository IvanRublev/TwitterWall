defmodule TwitterWallWeb.ApiControllerTest do
  use TwitterWallWeb.ConnCase, async: true

  import Builders
  import Stubs

  alias TwitterWallWeb.AuthToken

  setup [:default_stubs]

  describe "GET /api/tweets should" do
    test "return 401 when no JWT auth header is given", %{conn: conn} do
      conn = get(conn, "/api/tw.json")
      assert json_response(conn, 401) == %{"result" => "Unauthorized"}
    end

    test "return 401 on malformed authorization header value", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "malformed")
        |> get("/api/tw.json")

      assert json_response(conn, 401) == %{"result" => "Malformed Authorization header"}
    end

    test "return 401 on invalid JWT signature", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer eyJhbG.eyJ0aG.invalid-b64enc-signature")
        |> get("/api/tw.json")

      assert json_response(conn, 401) == %{"result" => "Invalid signature"}
    end

    test "return 400 on expired request", %{conn: conn} do
      token = AuthToken.generate_and_sign!(%{"exp" => Joken.current_time() - 1})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/tw.json")

      assert json_response(conn, 400) == %{"result" => "Outdated"}
    end

    test "return 400 on no expiration time given", %{conn: conn} do
      token = AuthToken.generate_and_sign!(%{"exp" => ""})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/tw.json")

      assert json_response(conn, 400) == %{"result" => "Outdated"}
    end

    test "returen 400 on no tweet_count value is given", %{conn: conn} do
      token =
        AuthToken.generate_and_sign!(%{
          "exp" => Joken.current_time() + 10,
          "tweet_count" => ""
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/tw.json")

      assert json_response(conn, 400) == %{"result" => "No tweet count"}
    end

    test "return status 400 for tweet_count > 20", %{conn: conn} do
      token =
        AuthToken.generate_and_sign!(%{
          "exp" => Joken.current_time() + 10,
          "tweet_count" => 400
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/tw.json")

      assert json_response(conn, 400) == %{"result" => "Can return only up to 20 tweets"}
    end

    test "return status 400 for tweet_count < 0", %{conn: conn} do
      token =
        AuthToken.generate_and_sign!(%{
          "exp" => Joken.current_time() + 10,
          "tweet_count" => -1
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/tw.json")

      assert json_response(conn, 400) == %{"result" => "Can return only up to 20 tweets"}
    end

    test "return empty response for 0 tweet_count", %{conn: conn} do
      token =
        AuthToken.generate_and_sign!(%{
          "exp" => Joken.current_time() + 10,
          "tweet_count" => "0"
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/tw.json")

      assert json_response(conn, 200) == %{"html" => ""}
    end

    test "return tweets in amount of JWT token tweet_count claim's value", %{conn: conn} do
      stub_wall_get_tweets(fn _arg ->
        tweets = Enum.map(1..4, &build_tweet(html: "tweet#{&1}", kind: if(rem(&1, 2) == 0, do: :liked, else: :posted)))
        build_tweet_aggregate(tweets: tweets, errors: [])
      end)

      token =
        AuthToken.generate_and_sign!(%{
          "exp" => Joken.current_time() + 10,
          "tweet_count" => 4
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/tw.json")

      assert %{
               "html" =>
                 "<div class=\"tw_box\"><div class=\"tw_posted\"></div>tweet1</div><div class=\"tw_box\"><div class=\"tw_liked\"></div>tweet2</div><div class=\"tw_box\"><div class=\"tw_posted\"></div>tweet3</div><div class=\"tw_box\"><div class=\"tw_liked\"></div>tweet4</div>"
             } = json_response(conn, 200)
    end

    test "return js snippet for tweets rendering", %{conn: conn} do
      stub_wall_get_tweets(fn _arg ->
        tweets = Enum.map(1..4, &build_tweet(html: "tweet#{&1}", kind: if(rem(&1, 2) == 0, do: :liked, else: :posted)))
        build_tweet_aggregate(tweets: tweets, errors: [])
      end)

      token =
        AuthToken.generate_and_sign!(%{
          "exp" => Joken.current_time() + 10,
          "tweet_count" => 4
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/tw.json")

      assert %{
               "js_rendering_snippet" => """
               <script>window.twttr = (function(d, s, id) {
                 var js, fjs = d.getElementsByTagName(s)[0],
                   t = window.twttr || {};
                 if (d.getElementById(id)) return t;
                 js = d.createElement(s);
                 js.id = id;
                 js.src = "https://platform.twitter.com/widgets.js";
                 fjs.parentNode.insertBefore(js, fjs);

                 t._e = [];
                 t.ready = function(f) {
                   t._e.push(f);
                 };

                 return t;
               }(document, "script", "twitter-wjs"));</script>
               """
             } = json_response(conn, 200)
    end

    test "return 500 on twitter wall failure", %{conn: conn} do
      stub_wall_get_tweets(fn _arg ->
        build_tweet_aggregate(tweets: [build_tweet()], errors: [%{status: 404}, %{status: 500}])
      end)

      token =
        AuthToken.generate_and_sign!(%{
          "exp" => Joken.current_time() + 10,
          "tweet_count" => 3
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/tw.json")

      assert json_response(conn, 500) == %{"result" => "Subsequent request failed"}
    end
  end
end
