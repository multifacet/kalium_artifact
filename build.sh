#!/bin/bash

set -ex

mkdir -p build 

pushd ./kalium
bazel build //runsc:runsc
cp bazel-bin/runsc/linux_amd64_static_pure_stripped/runsc ../build/
popd

pushd ./kalium-proxy
./build.sh
cp seclambda ../build/
popd


## Note: libzmq is built along with kalium proxy
pushd ./kalium-controller
make
cp ctr instid policy_test.json ../build/
popd

echo "Kalium kalium-proxy and controller built"
echo "Copy ./build/runsc and ./build/seclambda into /usr/local/bin in all the kubernetes nodes"
