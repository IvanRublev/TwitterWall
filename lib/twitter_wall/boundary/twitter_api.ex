defmodule TwitterWall.Boundary.TwitterAPI do
  @moduledoc """
  Twitter API endpoint
  """

  use Knigge, implementation: Application.compile_env(:twitter_wall, __MODULE__, TwitterWall.Boundary.TwitterAPIImpl)

  @type url_string :: String.t()

  @callback favorites(count :: integer()) :: {:ok, [map()]} | {:error, any()}
  @callback user_timeline(count :: integer()) :: {:ok, [map()]} | {:error, any()}
  @callback oembed(url_string()) :: {:ok, [String.t()]} | {:error, any()}
end
