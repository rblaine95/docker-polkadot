###################
# --- builder --- #
###################
FROM docker.io/rust:1.71 AS builder

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y install \
        build-essential git clang \
        libclang-dev pkg-config libssl-dev cmake \
        protobuf-compiler

WORKDIR /opt
ARG VERSION=1.0.0
RUN git clone https://github.com/paritytech/polkadot.git -b v$VERSION --depth 1
WORKDIR /opt/polkadot
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
RUN ./scripts/init.sh
RUN rustup target add wasm32-unknown-unknown
RUN cargo build --release

##################
# --- runner --- #
##################
FROM docker.io/debian:12-slim

COPY --from=builder /opt/polkadot/target/release/polkadot /usr/local/bin/polkadot

RUN addgroup --gid 65532 nonroot \
    && adduser --system --uid 65532 --gid 65532 --home /home/nonroot nonroot

USER 65532
EXPOSE 30333 9933 9944
VOLUME /data

ENTRYPOINT [ "/usr/local/bin/polkadot" ]
