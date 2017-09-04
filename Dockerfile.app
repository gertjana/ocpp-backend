FROM msaraiva/elixir
MAINTAINER You

# Important! Update this no-op ENV to refresh image
ENV REFRESHED_AT 2016–05–02
ENV HOME /root

# Upgrade all packages
RUN apk — update upgrade && \
 apk add bash && \
 rm -rf /var/cache/apk/*

ARG APP
ARG VERSION

ENV MIX_ENV prod
ENV PORT 8383
ENV APP_PATH /_build/$MIX_ENV/rel/$APP

RUN mkdir -p $APP
COPY $APP_PATH/bin                           /$APP/bin
COPY $APP_PATH/lib                           /$APP/lib
COPY $APP_PATH/releases/start_erl.data       /$APP/releases/start_erl.data
COPY $APP_PATH/releases/$VERSION/libexec     /$APP/releases/$VERSION/libexec
COPY $APP_PATH/releases/$VERSION/$APP.sh     /$APP/releases/$VERSION/$APP.sh
COPY $APP_PATH/releases/$VERSION/$APP.boot   /$APP/releases/$VERSION/$APP.boot
COPY $APP_PATH/releases/$VERSION/$APP.rel    /$APP/releases/$VERSION/$APP.rel
COPY $APP_PATH/releases/$VERSION/$APP.script /$APP/releases/$VERSION/$APP.script
COPY $APP_PATH/releases/$VERSION/$APP.boot  /$APP/releases/$VERSION/$APP.boot
COPY $APP_PATH/releases/$VERSION/sys.config  /$APP/releases/$VERSION/sys.config
COPY $APP_PATH/releases/$VERSION/vm.args     /$APP/releases/$VERSION/vm.args

WORKDIR /$APP

RUN mv bin/$APP bin/start

EXPOSE $PORT

CMD trap exit TERM; bin/start foreground & wait