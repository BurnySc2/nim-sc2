# https://docs.earthly.dev/
VERSION 0.6
# Run with
# earthly +all --NIMVERSION=1.6.14
ARG NIMVERSION=1.6.14
FROM nimlang/nim:${NIMVERSION}-ubuntu
WORKDIR /root/nim_sc2

setup:
    RUN nimble install -y nimpb
    RUN nimble install -y ws
    COPY . ./

run-local:
    LOCALLY
    # TODO Run a game on host machine - use wine

run:
    FROM +setup
    # TODO Run a game in container - use linux binary

compile-all:
    FROM +setup
    RUN nim c examples/terran/*.nim
    RUN nim c -d:release examples/terran/*.nim
    # TODO Compile all library files

run-tests:
    FROM +setup
    RUN testament pattern "tests/*.nim"

all:
    BUILD +compile-all
    BUILD +run-tests
