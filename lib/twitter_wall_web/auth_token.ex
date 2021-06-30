defmodule TwitterWallWeb.AuthToken do
  @moduledoc """
  Module adapting Joken config to generate and validate JWT tokens.
  """
  use Joken.Config,
    default_signer: :none

  alias TwitterWall.Config
  alias TwitterWall.Utility.IntegerParser

  def before_sign(_opts, {token_config, _signer}) do
    signer = Config.get() |> Keyword.fetch!(:tw_api_joken_signer)
    {:cont, {token_config, signer}}
  end

  def before_verify(_opts, {token, _signer}) do
    signer = Config.get() |> Keyword.fetch!(:tw_api_joken_signer)
    {:cont, {token, signer}}
  end

  def token_config do
    add_claim(%{}, "exp", nil, fn val ->
      case IntegerParser.parse_integer_safe(val) do
        {:ok, int_val} -> int_val > Joken.current_time()
        _ -> false
      end
    end)
  end
end
