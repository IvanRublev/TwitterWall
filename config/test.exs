use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :twitter_wall, TwitterWallWeb.Endpoint, server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :twitter_wall, TwitterWall, TwitterWallMock
config :twitter_wall, TwitterWall.Boundary.TwitterAPI, TwitterWall.Boundary.TwitterAPIMock
