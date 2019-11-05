defmodule TwitterWall.Infra.CacheService do
  @moduledoc """
  A behaviour module for implementing a html Cache.
  """
  use Knigge, otp_app: :twitter_wall

  @callback start_link(arg :: list()) :: GenServer.on_start()

  @callback htmls(count :: non_neg_integer(), valid_on: date :: DateTime.t()) ::
              :empty | :count_mismatch | :expired | {:hit, list(String.t())}

  @callback put(htmls :: list(String.t()), count :: non_neg_integer(),
              expire_on: date :: DateTime.t()
            ) :: :ok
end
