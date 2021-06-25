FROM ghcr.io/rblaine95/rust AS builder

ARG VERSION=0.9.7

WORKDIR /opt

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y install build-essential git clang libclang-dev pkg-config libssl-dev

RUN git clone https://github.com/paritytech/polkadot.git -b v$VERSION && \
    cd polkadot && \
    ./scripts/init.sh && \
    cargo build --release

FROM ghcr.io/rblaine95/debian:10-slim

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt && \
    useradd -ms /bin/bash dot && \
    mkdir -p /home/dot/.local/share/polkadot && \
    chown -R dot:dot /home/dot/.local/share/polkadot

COPY --from=builder /opt/polkadot/target/release/polkadot /usr/local/bin/polkadot

USER dot

WORKDIR /home/dot

VOLUME /home/dot/.local/share/polkadot

ENTRYPOINT [ "/usr/local/bin/polkadot" ]
