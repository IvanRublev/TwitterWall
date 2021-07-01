import Config

secret_key_base = System.get_env("SECRET_KEY_BASE")
port = String.to_integer(System.get_env("PORT") || "4000")

config :twitter_wall, TwitterWallWeb.Endpoint,
  secret_key_base: secret_key_base,
  url: [host: "localhost", port: port],
  http: [
    port: port,
    transport_options: [socket_opts: [:inet6]]
  ],
  live_view: [signing_salt: System.get_env("LV_SIGNING_SALT")]

config :twitter_wall, :general,
  screen_name: System.get_env("TWITTER_USER_SCREEN_NAME"),
  default_tweet_count: 3,
  tweet_base_uri: "https://twitter.com/interior/status",
  cached_aggregate_ttl: 1_000 * 60 * 3

config :twitter_wall, :twitter_api_settings,
  twitter_api_1_1_base: "https://api.twitter.com/1.1",
  twitter_publish_base: "https://publish.twitter.com",
  tweet_base_uri: "https://twitter.com/interior/status",
  bearer_token: System.get_env("BEARER_TOKEN"),
  oauth_consumer_key: System.get_env("OAUTH_CONSUMER_KEY"),
  oauth_consumer_secret: System.get_env("OAUTH_CONSUMER_SECRET"),
  oauth_token: System.get_env("OAUTH_TOKEN"),
  oauth_token_secret: System.get_env("OAUTH_TOKEN_SECRET")

# Joken JWT signer for client verification
config :joken,
  default_signer: [
    signer_alg: "HS512",
    key_octet: System.get_env("JWT_HS_KEY")
  ]
