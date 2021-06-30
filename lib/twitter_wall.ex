defmodule TwitterWall do
  @moduledoc """
  Twitter Wall context that is a Service returning liked and posted tweets aggregated into single timeline.
  """

  use Knigge, implementation: Application.compile_env(:twitter_wall, __MODULE__, TwitterWallImpl)

  alias TwitterWall.Core.TweetAggregate

  @callback validate_count(count_string :: String.t()) :: {:ok, integer()} | {:error, String.t()}
  @callback get_tweets(count :: integer()) :: TweetAggregate.t()
end
