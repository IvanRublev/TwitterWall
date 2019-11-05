# TwitterWall

[![Build Status](https://travis-ci.org/IvanRublev/TwitterWall.svg?branch=master)](https://travis-ci.org/IvanRublev/TwitterWall) [![Coverage Status](https://coveralls.io/repos/github/IvanRublev/TwitterWall/badge.svg)](https://coveralls.io/github/IvanRublev/TwitterWall) ![Method TDD](https://img.shields.io/badge/method-TDD-blue) [![Uptime Robot ratio (7 days)](https://img.shields.io/uptimerobot/ratio/7/m783792183-0d609ad00cc5d32c7dcabce1)](https://tw.ivanrublev.me)

A simple microservice to display posted and liked tweets of a person written in Elixir.

An instance of the app is deployed with Gigalixir on Google Cloud Platform and accessible on https://tw.ivanrublev.me. It displays last three posted + liked tweets from the [author's Twitter account](https://twitter.com/levvibraun). 

The app has an API endpoint accessible at `/api/tw.json` providing the requested number of tweets as html. A JWT key is required to call the endpoint, that can be provided on request. One example of the microservice usage is on the author's homepage on https://ivanrublev.me/#twitterwall

## Deployment

The app is prepared according to https://12factor.net/ methodology. The app's configuration is stored in environment variables.

Deployment options are:

* Docker image for local testing, can be produced with `cd deploy && ./build_image.sh`

* Gigalixir, create an app according to the service's instructions and complete deployment with `cd deploy && ./deploy_gigalixir.sh`

## Installation for development

You can install an Elixir environment to run the project on macOS using the asdf version manager:

  * Install https://asdf-vm.com/ runtime management tool with `brew install asdf`
  * Add it to the shell with
    ```
    echo -e '\n. $(brew --prefix asdf)/asdf.sh' >> ~/.bash_profile
    echo -e '\n. $(brew --prefix asdf)/etc/bash_completion.d/asdf.bash' >> ~/.bash_profile
    ```
  * Restart the terminal
  * Install asdf plugins:
    ```
    asdf plugin-add elixir
    asdf plugin-add erlang
    asdf plugin-add nodejs
    ```
  * Install Elixir/Erlang/NodeJS runtimes in project's directory with `cd TwitterWall && asdf install` 

  * Install direnv and set it globally if wasn't done before
    + `asdf plugin-add direnv && asdf install direnv 2.20.0 && asdf global  direnv 2.20.0`
    + Follow the [instructions to hook direnv](https://github.com/direnv/direnv/blob/master/docs/hook.md) into your SHELL


## Development Webserver

To start the project's webserver:

  * In the project's directory `cd TwitterWall`
  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install && cd -`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


### Start with secrets populated

To start the project's webserver with secrets values populated with environment variables value you can create the following `.env` file in the project's directory:

```
TWITTER_USER_SCREEN_NAME=u
BEARER_TOKEN=a
OAUTH_CONSUMER_KEY=b
OAUTH_CONSUMER_SECRET=c
OAUTH_TOKEN=d
OAUTH_TOKEN_SECRET=e
```

Then allow the file with `cd TwitterWall && direnv allow`. And start the Phoenix endpoint with `./emix.sh phx.server`

## Licence

The licence is in [LICENSE.MD](LICENSE.MD) file.
