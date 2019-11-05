# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configure options for Application
opts = []
config :twitter_wall, :app_start_options, opts

# Configures the endpoint
config :twitter_wall, TwitterWallWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "VVQQetdG8FjT2oV2T2kIatQAnmdhjslX84vuqdFBo4nywr8y3jNXgZCMlMqbieNx",
  render_errors: [view: TwitterWallWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TwitterWall.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Time to set html cache expiration
config :twitter_wall, :cached_html_validity_ms, 3 * 60 * 60 * 1000

# Count of tweets to display on wall
config :twitter_wall, :twitter_wall_tweets_count, 3

# Set dependencies to be injected
config :twitter_wall,
       TwitterWall,
       (opts[:no_caches] && TwitterWall.OnlineWall) || TwitterWall.CachedWall

config :twitter_wall, TwitterWall.Infra.OnlineWallService, TwitterWall.OnlineWall

config :twitter_wall,
       TwitterWall.Infra.TwitterService,
       Twitter

config :twitter_wall, TwitterWall.Infra.CacheService, Cache.Memory

# Endpoint addresses
config :twitter_wall, twitter_api_1_1_base: "https://api.twitter.com/1.1"
config :twitter_wall, twitter_api_2_base: "https://api.twitter.com/2"
config :twitter_wall, twitter_publish_base: "https://publish.twitter.com"
config :twitter_wall, tweet_base_url: "https://twitter.com/interior/status"
# User name
config :twitter_wall, screen_name: {:system, "TWITTER_USER_SCREEN_NAME", "screen_name"}
# Authentication tokens
config :twitter_wall, bearer_token: {:system, "BEARER_TOKEN", "bearer_token"}
config :twitter_wall, oauth_consumer_key: {:system, "OAUTH_CONSUMER_KEY", "oauth_consumer_key"}

config :twitter_wall,
  oauth_consumer_secret: {:system, "OAUTH_CONSUMER_SECRET", "oauth_consumer_secret"}

config :twitter_wall, oauth_token: {:system, "OAUTH_TOKEN", "oauth_token"}
config :twitter_wall, oauth_token_secret: {:system, "OAUTH_TOKEN_SECRET", "oauth_token_secret"}

# Joken JWT signer for verification
config :joken,
  default_signer: [
    signer_alg: "HS512",
    key_octet: {:system, "JWT_HS_KEY", "hs_key"}
  ]

config :knigge, :check_if_exists?, false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
