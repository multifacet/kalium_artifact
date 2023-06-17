FROM ubuntu:18.04 as base

RUN mkdir -p /build/bin
WORKDIR /build
COPY ./setup-prerequisites-docker.sh /build
RUN /build/setup-prerequisites-docker.sh

RUN pwd
RUN git clone https://github.com/multifacet/kalium
RUN git clone https://github.com/multifacet/kalium-controller
RUN git clone https://github.com/multifacet/kalium-proxy
RUN cd kalium && git checkout bleeding && /build/bazel/bin/bazel build //runsc:runsc && cp /build/kalium/bazel-bin/runsc/linux_amd64_pure_stripped/runsc /build/bin/runsc_stock

RUN cd kalium && git checkout artifact && /build/bazel/bin/bazel build //runsc:runsc && cp /build/kalium/bazel-bin/runsc/linux_amd64_static_pure_stripped/runsc /build/bin/

RUN cd kalium-proxy && git checkout artifact && ./build.sh && cp seclambda /build/bin
RUN cd kalium-controller && git checkout artifact && make && cp ctr instid policy_test.json /build/bin
