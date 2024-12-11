###################
# --- builder --- #
###################
FROM docker.io/rust:1.83 AS builder

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y install \
      libclang-dev protobuf-compiler

ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
RUN rustup target add wasm32-unknown-unknown
RUN rustup component add rust-src

WORKDIR /opt
ARG VERSION=polkadot-stable2409-2
RUN git clone https://github.com/paritytech/polkadot-sdk.git -b $VERSION --depth 1
WORKDIR /opt/polkadot-sdk
RUN cargo build --locked --release --package polkadot

##################
# --- runner --- #
##################
FROM docker.io/debian:12-slim

RUN addgroup --gid 65532 nonroot \
  && adduser --system --uid 65532 --gid 65532 --home /home/nonroot nonroot

COPY --from=builder /opt/polkadot-sdk/target/release/polkadot /usr/local/bin/polkadot
# COPY --from=builder /opt/polkadot-sdk/target/release/polkadot-execute-worker /usr/local/bin/polkadot-execute-worker
# COPY --from=builder /opt/polkadot-sdk/target/release/polkadot-parachain /usr/local/bin/polkadot-parachain
# COPY --from=builder /opt/polkadot-sdk/target/release/polkadot-prepare-worker /usr/local/bin/polkadot-prepare-worker
# COPY --from=builder /opt/polkadot-sdk/target/release/polkadot-substrate-node /usr/local/bin/polkadot-substrate-node

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
