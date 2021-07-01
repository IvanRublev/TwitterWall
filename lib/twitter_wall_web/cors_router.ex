defmodule TwitterWallWeb.CORSRouter do
  @moduledoc """
  Module configuring Corsica plugin to enable /api endpoint to be CORS compatible.
  """
  use Corsica.Router,
    origins: "*",
    allow_credentials: true,
    allow_headers: :all,
    max_age: 600

  resource("/api/*")
end
