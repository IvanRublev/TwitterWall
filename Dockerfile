ARG ELIXIR_VERSION
ARG OTP_VERSION
ARG ALPINE_VERSION
ARG BUILD_RELEASE_FROM

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION} as build

ENV MIX_ENV=prod

WORKDIR /app

RUN \
  apk upgrade --no-cache && \
  apk add \
    --no-cache \
    build-base \
    yarn \
    git && \

  mix local.hex --force && \
  mix local.rebar --force

COPY .env /release/.env
COPY ./.git /workspace

RUN \
  export $(grep -v '^#' /release/.env | xargs -0) && \
  export PORT=8000 && \

  git clone --local /workspace . && \
  git checkout "${BUILD_RELEASE_FROM}" && \
  ls -al && \

  mix deps.get --only prod && \
  cd assets && \
  yarn install && \
  yarn run deploy && \
  cd .. && \
  mix phx.digest && \
  mix compile && \
  mix release && \
  ls -al _build/prod && \
  ls -al _build/prod/rel

# Start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM alpine:${ALPINE_VERSION} AS app

ENV USER="phoenix"
ENV HOME=/home/"${USER}"
ENV APP_DIR="${HOME}/app"

RUN \
  apk upgrade --no-cache && \
  apk add --no-cache \
    openssl \
    libgcc \
    libstdc++ \
    ncurses-libs && \

  # Creates a unprivileged user to run the app
  addgroup \
   -g 1000 \
   -S "${USER}" && \
  adduser \
   -s /bin/sh \
   -u 1000 \
   -G "${USER}" \
   -h "${HOME}" \
   -D "${USER}" && \

  su "${USER}" sh -c "mkdir ${APP_DIR}"

# Everything from this line onwards will run in the context of the unprivileged user.
USER "${USER}"

WORKDIR "${APP_DIR}"

COPY --from=build --chown="${USER}":"${USER}" /app/_build/prod/rel/twitter_wall ./

ENTRYPOINT ["./bin/twitter_wall"]

CMD ["start"]
