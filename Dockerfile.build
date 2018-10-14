FROM bitwalker/alpine-elixir:1.7.3
MAINTAINER You

# Important!  Update this no-op ENV to refresh image
ENV REFRESHED_AT 2018-09-21
ENV HOME /root

COPY . /build

ARG APP
ENV MIX_ENV prod

WORKDIR /build

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix deps.get --only prod
RUN mix compile 
RUN echo y | mix release.clean --implode
RUN mix release

WORKDIR /build

CMD ["/bin/sh"]