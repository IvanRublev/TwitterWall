defmodule TwitterWall.Application do
  @moduledoc false

  use Application

  alias TwitterWall.Config

  def start(_type, _args) do
    children = [
      TwitterWallWeb.Telemetry,
      {Phoenix.PubSub, name: TwitterWall.PubSub},
      TwitterWallWeb.Endpoint,
      {Finch, name: TwitterAPI},
      TwitterWall.Boundary.Cache
    ]

    cfg = Application.fetch_env!(:joken, :default_signer)
    signer = Joken.Signer.parse_config(:default_signer) || raise("signer can't be nil. Joken failed to parse its configuration #{inspect(cfg)}.")
    Config.merge(:global, tw_api_joken_signer: signer)

    opts = [strategy: :one_for_one, name: TwitterWall.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    TwitterWallWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
