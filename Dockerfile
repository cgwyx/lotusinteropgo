# build container stage
FROM golang:1.14.2 AS build-env

# branch or tag of the lotus version to build
ARG BRANCH=interopnet
#ARG BRANCH=master

RUN echo "Building lotus from branch $BRANCH"

RUN apt-get update -y && \
    apt-get install sudo curl git mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config -y

WORKDIR /

RUN git clone -b $BRANCH https://github.com/filecoin-project/lotus.git &&\
    cd lotus &&\
    make clean all &&\
    make install &&\
    make build bench


# runtime container stage
FROM ubuntu:18.04

# Instead of running apt-get just copy the certs and binaries that keeps the runtime image nice and small
# RUN apt-get update && \
#    apt-get install sudo ca-certificates mesa-opencl-icd ocl-icd-opencl-dev -y && \
#    rm -rf /var/lib/apt/lists/*
COPY --from=build-env /lotus /lotus
COPY --from=build-env /etc/ssl/certs /etc/ssl/certs
#COPY LOTUS_VERSION /VERSION

COPY --from=build-env /lib/x86_64-linux-gnu/libdl.so.2 /lib/libdl.so.2
COPY --from=build-env /lib/x86_64-linux-gnu/libutil.so.1 /lib/libutil.so.1 
COPY --from=build-env /usr/lib/x86_64-linux-gnu/libOpenCL.so.1.0.0 /lib/libOpenCL.so.1
COPY --from=build-env /lib/x86_64-linux-gnu/librt.so.1 /lib/librt.so.1
COPY --from=build-env /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/libgcc_s.so.1

#COPY config/config.toml /root/config.toml
#COPY scripts/entrypoint /bin/entrypoint

RUN chmod a+x /lotus/lotus && \
    chmod a+x /lotus/lotus-storage-miner && \
    chmod a+x /lotus/lotus-seal-worker && \
    chmod a+x /lotus/bench
    ln -s /lotus/lotus /usr/bin/lotus
    ln -s /lotus/lotus-storage-miner /usr/bin/lotus-storage-miner
    ln -s /lotus/lotus-seal-worker /usr/bin/lotus-seal-worker

#chmod u+x /lotus

VOLUME ["/root","/var"]


# API port
EXPOSE 1234/tcp

# API port
EXPOSE 2345/tcp

# API port
EXPOSE 3456/tcp

# P2P port
EXPOSE 1347/tcp


ENV IPFS_GATEWAY=https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/

ENV FIL_PROOFS_MAXIMIZE_CACHING=1

WORKDIR /lotus


CMD ["./lotus", "daemon", "&"]
#ENTRYPOINT ["/bin/entrypoint"]
#CMD ["-d"]

