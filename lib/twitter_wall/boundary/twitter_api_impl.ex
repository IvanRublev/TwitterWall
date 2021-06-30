defmodule TwitterWall.Boundary.TwitterAPIImpl do
  @moduledoc """
  Implementation of TwitterAPI callbacks
  """

  alias TwitterWall.Boundary.TwitterAPI.Client
  alias TwitterWall.Boundary.TwitterAPI.Config
  alias TwitterWall.Config, as: GeneralConfig
  alias TwitterWall.Utility.URIBuilder

  @behaviour TwitterWall.Boundary.TwitterAPI

  @impl true
  def favorites(count) do
    config = Config.get()

    uri =
      config
      |> Keyword.fetch!(:twitter_api_1_1_base)
      |> URIBuilder.uri_string_by_appending_path("/favorites/list.json")

    screen_name = GeneralConfig.get() |> Keyword.fetch!(:screen_name)
    params = %{"count" => count, "screen_name" => screen_name}

    bearer_token = Keyword.fetch!(config, :bearer_token)
    headers = [{"authorization", "Bearer #{bearer_token}"}]

    uri
    |> Client.get_request(params, headers)
    |> Client.validate_status_code()
    |> Client.decode_json_response(keys: :atoms)
  end

  @impl true
  def user_timeline(count) do
    config = Config.get()

    uri =
      config
      |> Keyword.fetch!(:twitter_api_1_1_base)
      |> URIBuilder.uri_string_by_appending_path("/statuses/user_timeline.json")

    screen_name = GeneralConfig.get() |> Keyword.fetch!(:screen_name)
    params = %{"count" => count, "screen_name" => screen_name}

    credentials =
      OAuther.credentials(
        consumer_key: Keyword.fetch!(config, :oauth_consumer_key),
        consumer_secret: Keyword.fetch!(config, :oauth_consumer_secret),
        token: Keyword.fetch!(config, :oauth_token),
        token_secret: Keyword.fetch!(config, :oauth_token_secret)
      )

    params_list = Enum.into(params, [])
    sign = OAuther.sign("get", uri, params_list, credentials)
    {auth_header, _} = OAuther.header(sign)
    headers = [auth_header]

    uri
    |> Client.get_request(params, headers)
    |> Client.validate_status_code()
    |> Client.decode_json_response(keys: :atoms)
  end

  @impl true
  def oembed(url_string) do
    config = Config.get()

    uri =
      config
      |> Keyword.fetch!(:twitter_publish_base)
      |> URIBuilder.uri_string_by_appending_path("/oembed")

    params = %{url: url_string, omit_script: true}

    uri
    |> Client.get_request(params)
    |> Client.validate_status_code()
    |> Client.decode_json_response(keys: :atoms)
    |> Client.get_field(:html)
  end
end
