defmodule TwitterWallWeb.Router do
  use TwitterWallWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwitterWallWeb do
    pipe_through :browser

    get "/", TweetController, :index
  end

  scope "/api", TwitterWallWeb do
    pipe_through :api

    get "/tw.json", ApiController, :tweets
  end
end
