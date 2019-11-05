defmodule TwitterWallWeb.AuthToken do
  @moduledoc """
  Module adapting Joken config to generate and validate JWT tokens.
  """
  use Joken.Config,
    default_signer: :none

  def before_sign(_opts, {token_config, _signer}) do
    {:cont, {token_config, Application.fetch_env!(:joken, :default_signer_struct)}}
  end

  def before_verify(_opts, {token, _signer}) do
    {:cont, {token, Application.fetch_env!(:joken, :default_signer_struct)}}
  end

  def token_config do
    add_claim(%{}, "exp", nil, fn val ->
      case Integer.Parse.safe(val) do
        {:ok, int_val} -> int_val > Joken.current_time()
        _ -> false
      end
    end)
  end
end
