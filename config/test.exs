use Mix.Config

# We don't run cache servers during test
config :twitter_wall, :app_start_options, no_caches: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :twitter_wall, TwitterWallWeb.Endpoint,
  http: [port: 4002],
  server: false

# Disable logging during tests
config :logger, backends: []

# Make cache expire fast in test mode
config :twitter_wall, :cached_html_validity_ms, 100

# Set dependencies to be injected
config :twitter_wall, TwitterWall, TwitterWall.Double

config :twitter_wall,
       TwitterWall.Infra.OnlineWallService,
       TwitterWall.Infra.OnlineWallService.Double

config :twitter_wall,
       TwitterWall.Infra.TwitterService,
       TwitterWall.Infra.TwitterService.Double

config :twitter_wall, TwitterWall.Infra.CacheService, TwitterWall.Infra.CacheService.Double

config :tesla, adapter: Tesla.Mock
