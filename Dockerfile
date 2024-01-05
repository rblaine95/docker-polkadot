###################
# --- builder --- #
###################
FROM docker.io/rust:1.75 AS builder

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y install \
      libclang-dev protobuf-compiler

WORKDIR /opt
ARG VERSION=polkadot-v1.5.0
RUN git clone https://github.com/paritytech/polkadot-sdk.git -b $VERSION --depth 1
WORKDIR /opt/polkadot-sdk
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
RUN rustup target add wasm32-unknown-unknown
RUN rustup component add rust-src
RUN cargo build --release --package polkadot

##################
# --- runner --- #
##################
FROM docker.io/debian:12-slim

COPY --from=builder /opt/polkadot-sdk/target/release/polkadot /usr/local/bin/polkadot

RUN addgroup --gid 65532 nonroot \
    && adduser --system --uid 65532 --gid 65532 --home /home/nonroot nonroot

USER 65532

# P2P
EXPOSE 30333
# RPC
EXPOSE 9933
# WS
EXPOSE 9944
# Prometheus
EXPOSE 9615

VOLUME /data

ENTRYPOINT [ "/usr/local/bin/polkadot" ]
