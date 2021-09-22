FROM debian:buster AS builder
RUN apt-get update && \
    apt-get install -y gcc g++ cmake libopenal-dev
