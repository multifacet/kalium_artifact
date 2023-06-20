FROM ubuntu:18.04 as base

ARG controllerHost

RUN mkdir -p /build/bin
WORKDIR /build
COPY ./setup-prerequisites-docker.sh /build
RUN /build/setup-prerequisites-docker.sh

#RUN pwd
RUN git clone https://github.com/multifacet/kalium
RUN git clone https://github.com/multifacet/kalium-controller
RUN git clone https://github.com/multifacet/kalium-proxy
RUN cd kalium && git checkout bleeding && /build/bazel/bin/bazel build //runsc:runsc && cp /build/kalium/bazel-bin/runsc/linux_amd64_pure_stripped/runsc /build/bin/runsc_stock

RUN cd kalium && git checkout artifact && sed -i "336s/.*/sandBox2seclambdaSend, seclambda2SandboxRecv, e := c.createSeclambdaProxy(\"$controllerHost\", 5000, conf, args.Spec)/" runsc/container/container.go && /build/bazel/bin/bazel build //runsc:runsc && cp /build/kalium/bazel-bin/runsc/linux_amd64_static_pure_stripped/runsc /build/bin/runsc_kalium

RUN cd kalium && git reset && git checkout artifact_microbench && sed -i "336s/.*/sandBox2seclambdaSend, seclambda2SandboxRecv, e := c.createSeclambdaProxy(\"$controllerHost\", 5000, conf, args.Spec)/" runsc/container/container.go && /build/bazel/bin/bazel build //runsc:runsc && cp /build/kalium/bazel-bin/runsc/linux_amd64_static_pure_stripped/runsc /build/bin/runsc_microbench

RUN cd kalium-proxy && git checkout artifact && ./build.sh && cp seclambda /build/bin
RUN cd kalium-controller && git checkout artifact && make && cp ctr instid policy_test.json /build/bin
