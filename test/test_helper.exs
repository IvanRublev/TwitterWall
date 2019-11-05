# Define test double modules
Mox.defmock(TwitterWall.Double, for: TwitterWall)

Mox.defmock(TwitterWall.Infra.OnlineWallService.Double, for: TwitterWall)

Mox.defmock(TwitterWall.Infra.TwitterService.Double, for: TwitterWall.Infra.TwitterService)

Mox.defmock(TwitterWall.Infra.CacheService.Double, for: TwitterWall.Infra.CacheService)

# Start ExUnit
ExUnit.start()
