defmodule TwitterWallWeb.ApiController do
  use TwitterWallWeb, :controller

  require Logger

  alias TwitterWall.Utility.IntegerParser
  alias TwitterWallWeb.AuthToken

  @rendering_snippet """
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

  def tweets(conn, _opts) do
    with header when not is_nil(header) <- List.first(get_req_header(conn, "authorization")),
         {:ok, token} <- token(header),
         {:ok, claims} <- AuthToken.verify(token),
         {:ok, claims} <- AuthToken.validate(claims),
         {:ok, tweet_count} <- IntegerParser.parse_integer_safe(claims["tweet_count"]),
         {:ok, tweet_count} <- range_count(tweet_count) do
      if tweet_count == 0 do
        json(conn, %{html: ""})
      else
        tweet_aggregate = TwitterWall.get_tweets(tweet_count)

        if Enum.empty?(tweet_aggregate.errors) do
          tweets_html =
            tweet_aggregate.tweets
            |> Enum.map(&wrap_kind_html(&1.html, &1.kind))
            |> Enum.join()

          json(conn, %{html: tweets_html, js_rendering_snippet: @rendering_snippet})
        else
          send_error(conn, 500, "Subsequent request failed")
        end
      end
    else
      nil ->
        send_error(conn, 401, "Unauthorized")

      {:error, :malformed} ->
        send_error(conn, 401, "Malformed Authorization header")

      {:error, :signature_error} ->
        send_error(conn, 401, "Invalid signature")

      {:error, :int_parse_failed} ->
        send_error(conn, 400, "No tweet count")

      {:error, :tweet_count_out_of_range} ->
        send_error(conn, 400, "Can return only up to 20 tweets")

      {:error, _} ->
        send_error(conn, 400, "Outdated")
    end
  end

  defp wrap_kind_html(tw_html, kind) do
    "<div class=\"tw_box\"><div class=\"tw_#{Atom.to_string(kind)}\"></div>#{tw_html}</div>"
  end

  defp token("Bearer " <> token) do
    Logger.debug("#{__MODULE__} got token: #{token}")
    {:ok, token}
  end

  defp token(_), do: {:error, :malformed}

  defp range_count(count) do
    if count > -1 and count < 21 do
      {:ok, count}
    else
      {:error, :tweet_count_out_of_range}
    end
  end

  defp send_error(conn, status, message) do
    Logger.debug("#{__MODULE__} error: #{message}.")

    conn
    |> put_status(status)
    |> json(%{result: message})
    |> halt()
  end
end
