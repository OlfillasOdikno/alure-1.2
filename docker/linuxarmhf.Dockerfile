FROM debian:buster AS builder
RUN dpkg --add-architecture armhf && apt-get update && \
    apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf cmake libopenal-dev:armhf

