defmodule TwitterWall do
  @moduledoc """
  A behaviour module for implementing the wall of tweets to be displayed.
  """
  use Knigge,
    otp_app: :twitter_wall

  @callback last_liked_or_posted(count :: non_neg_integer) ::
              {:ok, list(String.t())} | {:error, list(any())}

  @callback last_liked_or_posted(
              count :: non_neg_integer,
              opts :: [now: DateTime.t(), reset_cache: bool()]
            ) ::
              {:ok, list(String.t())} | {:error, list(any())}
end
