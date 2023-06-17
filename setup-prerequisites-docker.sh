#!/bin/bash

set -ex

BAZEL_INSTALL_DIR=/build/bazel

apt update
apt install -y wget curl zlib1g-dev unzip \
    git build-essential libtool \
    pkg-config autotools-dev autoconf automake cmake \
    uuid-dev libpcre3-dev valgrind liblzma-dev make \
    python3 python3-pip python sudo

echo "Setting up Bazel"
mkdir -p $BAZEL_INSTALL_DIR
wget https://github.com/bazelbuild/bazel/releases/download/1.2.1/bazel-1.2.1-installer-linux-x86_64.sh
chmod +x bazel-1.2.1-installer-linux-x86_64.sh

./bazel-1.2.1-installer-linux-x86_64.sh --prefix=$BAZEL_INSTALL_DIR
#sudo cp $BAZEL_INSTALL_DIR/bin/bazel /usr/local/bin

echo "Building lz4"
git clone https://github.com/lz4/lz4
pushd lz4
make install
popd

echo "Building libzmq"
apt remove libunwind-dev
apt install -y \
    git build-essential libtool \
    pkg-config autotools-dev autoconf automake cmake \
    uuid-dev libpcre3-dev valgrind liblzma-dev
wget https://github.com/zeromq/libzmq/releases/download/v4.2.2/zeromq-4.2.2.tar.gz
tar -xvf zeromq-4.2.2.tar.gz
pushd zeromq-4.2.2
mkdir -p build
cd build
../configure
make install -j$(nproc)
ldconfig
popd

echo "Building czmq"
wget https://github.com/zeromq/czmq/releases/download/v4.2.0/czmq-4.2.0.tar.gz
tar -xvf czmq-4.2.0.tar.gz
pushd czmq-4.2.0
mkdir -p build
cd build
cmake ..
make install
ldconfig
popd

