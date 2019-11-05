#!/bin/bash
trap 'echo Build failed. An error occured while executing command at `basename $0`:${LINENO}. Try mix clean and restart.' ERR
set -e

type envsubst >/dev/null 2>&1 || { echo >&2 "
envsubst is requeired for this script. 
On macOS it can be installed with the following Homebrew command:
    
    brew install gettext && brew link --force gettext

"; exit 1; }

cd ..
echo "
=== Run code checks
"
mix compile
mix credo list
mix dialyzer

echo "
=== Run unit tests
"
mix coveralls

echo "
=== Security check for Prod environment
"
MIX_ENV=prod mix sobelow --verbose --private --exit medium -i Config.HTTPS,Config.CSP

echo "
=== Specify Environment variables

*********************************************************************************************
* WARNING: Secrets would be saved into a file in Docker image an can be retrived from there.
* Use this build is for debugging purposes only. Remove the docker image afterwards.
*********************************************************************************************
"
echo -n "Continue (y/n)? "
read answer
if [ "$answer" != "${answer#[Nn]}" ] ;then
    exit 2
fi

export SECRET_KEY_BASE=`mix phx.gen.secret`
export COOKIE=`mix phx.gen.secret`
export PORT=80
export HOST="localhost"

if [[ -f ".env" ]]; then
    export $(cat .env | xargs)
else
    for vn in TWITTER_USER_SCREEN_NAME BEARER_TOKEN OAUTH_CONSUMER_KEY OAUTH_CONSUMER_SECRET OAUTH_TOKEN OAUTH_TOKEN_SECRET JWT_HS_KEY; do
        read -p "${vn}:" usr_str
        export ${vn}=$usr_str
        echo "
        "
    done
fi

export GEN_ENV_FILE=./__env.build
echo "
SECRET_KEY_BASE=${SECRET_KEY_BASE}
COOKIE=${COOKIE}
PORT=${PORT}
HOST=${HOST}
TWITTER_USER_SCREEN_NAME=${TWITTER_USER_SCREEN_NAME}
BEARER_TOKEN=${BEARER_TOKEN}
OAUTH_CONSUMER_KEY=${OAUTH_CONSUMER_KEY}
OAUTH_CONSUMER_SECRET=${OAUTH_CONSUMER_SECRET}
OAUTH_TOKEN=${OAUTH_TOKEN}
OAUTH_TOKEN_SECRET=${OAUTH_TOKEN_SECRET}
JWT_HS_KEY=${JWT_HS_KEY}
" > $GEN_ENV_FILE
cat $GEN_ENV_FILE

export ENTRYPOINT_FILE=entrypoint.sh
export GEN_ENTRYPOINT_FILE=./__entrypoint.sh
export ENV_FILE=.env
envsubst < ./deploy/$ENTRYPOINT_FILE > $GEN_ENTRYPOINT_FILE

echo "
=== Build Docker image
"
export $(cat .tool-versions | sed -e "s/ /=/g" | xargs)
export ELIXIR_BUILD_IMG="elixir:$elixir-alpine"
export NODE_BUILD_IMG=node:$nodejs
export DEPLOY_IMG=alpine:3.9
export APP_NAME=`mix run --no-start -e "Mix.Project.get.project[:app] |> Atom.to_string() |> IO.puts()"`

export GEN_DOCKER_FILE=./deploy/Dockerfile.build
envsubst < ./deploy/Dockerfile > $GEN_DOCKER_FILE
cat $GEN_DOCKER_FILE
docker build -t $APP_NAME:latest -f $GEN_DOCKER_FILE .
rm $GEN_DOCKER_FILE
rm $GEN_ENV_FILE
rm $GEN_ENTRYPOINT_FILE

echo "
Build successful.

To run a container locally execute the following command:
    
    docker stop $APP_NAME ; docker rm $APP_NAME ; docker run -p 8080:$PORT -d --name $APP_NAME $APP_NAME:latest


Then the Website will be accessible at localhost:8080
"
