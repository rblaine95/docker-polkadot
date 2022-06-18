###################
# --- builder --- #
###################
FROM docker.io/rust:1.61 AS builder

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y install \
        build-essential git clang \
        libclang-dev pkg-config libssl-dev cmake

WORKDIR /opt
ARG VERSION=0.9.24
RUN git clone https://github.com/paritytech/polkadot.git -b v$VERSION --depth 1
WORKDIR /opt/polkadot
RUN ./scripts/init.sh
RUN cargo build --release

##################
# --- runner --- #
##################
FROM gcr.io/distroless/cc

COPY --from=builder /opt/polkadot/target/release/polkadot /usr/local/bin/polkadot

USER nonroot
WORKDIR /home/nonroot
EXPOSE 30333 9933 9944
VOLUME /data

ENTRYPOINT [ "/usr/local/bin/polkadot" ]
