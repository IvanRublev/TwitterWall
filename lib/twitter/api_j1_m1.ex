defmodule Twitter.ApiJ1M1 do
  @moduledoc """
  A module implementing HTTP client for Twitter API v1.1
  """
  use Tesla

  @base_url Application.fetch_env!(:twitter_wall, :twitter_api_1_1_base)

  plug Tesla.Middleware.BaseUrl, @base_url
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  defp config() do
    %{
      screen_name: Confex.fetch_env!(:twitter_wall, :screen_name),
      bearer_token: Confex.fetch_env!(:twitter_wall, :bearer_token),
      oauth_consumer_key: Confex.fetch_env!(:twitter_wall, :oauth_consumer_key),
      oauth_consumer_secret: Confex.fetch_env!(:twitter_wall, :oauth_consumer_secret),
      oauth_token: Confex.fetch_env!(:twitter_wall, :oauth_token),
      oauth_token_secret: Confex.fetch_env!(:twitter_wall, :oauth_token_secret)
    }
  end

  def favorites(count) do
    conf = config()

    get("/favorites/list.json",
      query: [count: count, screen_name: conf.screen_name],
      headers: [{"Authorization", "Bearer #{conf.bearer_token}"}]
    )
  end

  def user_timeline(count) do
    conf = config()

    creds =
      OAuther.credentials(
        consumer_key: conf.oauth_consumer_key,
        consumer_secret: conf.oauth_consumer_secret,
        token: conf.oauth_token,
        token_secret: conf.oauth_token_secret
      )

    path = "/statuses/user_timeline.json"
    params = [count: count, screen_name: conf.screen_name]
    params_str = Enum.map(params, fn {key, val} -> {Atom.to_string(key), val} end)
    sign = OAuther.sign("get", @base_url <> path, params_str, creds)
    {auth_header, _} = OAuther.header(sign)

    get(path,
      query: params,
      headers: [auth_header]
    )
  end
end
