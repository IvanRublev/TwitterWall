# TwitterWall

[![Build Status](https://travis-ci.com/IvanRublev/TwitterWall.svg?branch=master)](https://travis-ci.com/IvanRublev/TwitterWall) [![Coverage Status](https://coveralls.io/repos/github/IvanRublev/TwitterWall/badge.svg)](https://coveralls.io/github/IvanRublev/TwitterWall) ![Method TDD](https://img.shields.io/badge/method-TDD-blue) [![Uptime Robot ratio (7 days)](https://img.shields.io/uptimerobot/ratio/7/m783792183-0d609ad00cc5d32c7dcabce1)](https://tw.ivanrublev.me)

A simple micro-service to display posted and liked tweets of a person written in Elixir.

An instance of the app is deployed with Gigalixir on Google Cloud Platform and accessible on https://tw.ivanrublev.me. It displays last three posted + liked tweets from the [author's Twitter account](https://twitter.com/levvibraun). 

The app has an API endpoint accessible at `/api/tw.json` providing the requested number of tweets as html. A JWT key is required to call the endpoint. Short living one can be generated with `mix bearer_token` command. One example of the micro-service integration is on the author's homepage on https://ivanrublev.me/#twitterwall

## Development

To start your Phoenix server:

  * Install dependencies with `mix setup`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

The app is prepared according to https://12factor.net/ methodology. The app's configuration is stored in environment variables.

Deployment options are:

* Gigalixir, create an app according to the service's instructions, setup .env file as shown below and complete deployment with `./deploy_gigalixir.sh`

* Docker images for Development and Production, can be produced by steps given below.

### Setup Env file

Copy the example file:

```
cp .env.example .env
```

Add the secrets generated with `mix phx.gen.secret` for the following keys in the `.env` file:

```
SECRET_KEY_BASE=generated_secret_1
LV_SIGNING_SALT=generated_secret_2
JWT_HS_KEY=generated_secret_3
```

Set the following keys to appropriate values from https://developer.twitter.com/en/portal/dashboard

* TWITTER_USER_SCREEN_NAME
* BEARER_TOKEN
* OAUTH_CONSUMER_KEY 
* OAUTH_CONSUMER_SECRET 
* OAUTH_TOKEN 
* OAUTH_TOKEN_SECRET 

### Dev

Docker compose mounts project's root folder into the dev container, so all changes are persisted.

Build the development image:

```
docker-compose build dev
```

Get a shell inside the docker container:

```
docker-compose run --rm --service-ports dev
```

In case you have already fetched the deps and build the app from the host you can remove the build and deps folder:

```
rm -rf _build deps && mix setup
```

Run server with:

```
iex -S mix phx.server
```

Visit http://localhost:4000 

### Prod

Docker checks outs files for release from the master branch.

Build the release:

```
docker-compose build release
```

Run the release:

```
docker-compose up prod
```

Visit http://localhost:8000


* Docker files are inspired by work of @exadra37.

## Licence

The licence is in [LICENSE.MD](LICENSE.MD) file.
