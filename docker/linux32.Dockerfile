FROM debian:buster AS builder
RUN dpkg --add-architecture i386 && apt-get update && \
    apt-get install -y gcc-multilib g++-multilib cmake libopenal-dev:i386
