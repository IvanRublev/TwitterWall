# Build dependencies
FROM ${ELIXIR_BUILD_IMG} as deps
ENV LANG=C.UTF-8
WORKDIR /opt/app
RUN apk add --no-cache \
  gcc \
  make
RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix hex.info
COPY mix.* /opt/app/ 
RUN mix deps.get --only prod && \
  MIX_ENV=prod mix deps.compile

# Build frontend assets
FROM ${NODE_BUILD_IMG} as frontend
ENV LANG=C.UTF-8
COPY assets/package.json /opt/app/
COPY --from=deps /opt/app/deps/phoenix /opt/deps/phoenix
COPY --from=deps /opt/app/deps/phoenix_html /opt/deps/phoenix_html
WORKDIR /opt/app
RUN npm install && \
  npm audit fix --only=prod
COPY assets /opt/app
RUN npm run deploy

# Build release from dependencies + assets + app source
FROM deps as builder
ENV LANG=C.UTF-8
WORKDIR /opt/app
COPY --from=frontend /opt/priv/static /opt/app/priv/static
COPY . /opt/app/
ENV MIX_ENV=prod
RUN mix phx.digest && \
 mix distillery.release --env=prod --no-tar

# Make production image
FROM ${DEPLOY_IMG}
ENV LANG=C.UTF-8
RUN apk add --no-cache \
  bash \
  libcap
COPY --from=builder /opt/app/_build/prod/rel/${APP_NAME} /opt/app/
COPY --from=builder /opt/app/${GEN_ENV_FILE} /opt/app/bin/${ENV_FILE}
COPY --from=builder /opt/app/${GEN_ENTRYPOINT_FILE} /opt/app/bin/${ENTRYPOINT_FILE}
RUN chmod +x /opt/app/bin/${ENTRYPOINT_FILE}
EXPOSE ${PORT}
WORKDIR /opt/app/bin
ENTRYPOINT ["./${ENTRYPOINT_FILE}"]
CMD ["./${APP_NAME} foreground"]
