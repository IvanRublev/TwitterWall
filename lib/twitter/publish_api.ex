defmodule Twitter.PublishApi do
  @moduledoc """
  A module implementing HTTP client for Twitter oEmbed API. To get an HTML representation of a Tweet.
  """
  use Tesla

  plug Tesla.Middleware.BaseUrl, Application.fetch_env!(:twitter_wall, :twitter_publish_base)
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  def oembed(url) do
    get("/oembed", query: [url: url, omit_script: true])
  end
end
