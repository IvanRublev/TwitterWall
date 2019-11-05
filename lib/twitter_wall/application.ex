defmodule TwitterWall.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Prepare signer with configuration from environment variable and keep for later use, see AuthToken module.
    cfg = Confex.Resolver.resolve!(Application.fetch_env!(:joken, :default_signer))
    Application.put_env(:joken, :default_signer, cfg)

    signer =
      Joken.Signer.parse_config(:default_signer) ||
        raise("signer can't be nil. Joken failed to parse configuration: #{cfg}")

    Application.put_env(:joken, :default_signer_struct, signer)

    # List all child processes to be supervised
    start_options = Application.fetch_env!(:twitter_wall, :app_start_options)
    children = cache_child(start_options) ++ [TwitterWallWeb.Endpoint]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TwitterWall.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cache_child(opts), do: (opts[:no_caches] && []) || [Cache]

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TwitterWallWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
