defmodule TwitterWall.Infra.OnlineWallService do
  @moduledoc """
  A behaviour module repeating TwitterWall behaviour.
  """
  use Knigge,
    behaviour: TwitterWall,
    otp_app: :twitter_wall
end
