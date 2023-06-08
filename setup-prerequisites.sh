#!/bin/bash

set -ex

BAZEL_INSTALL_DIR=$HOME/bazel

sudo apt update
sudo apt install wget curl zlib1g-dev

echo "Setting up Bazel"
mkdir -p $BAZEL_INSTALL_DIR
wget https://github.com/bazelbuild/bazel/releases/download/1.2.1/bazel-1.2.1-installer-linux-x86_64.sh
chmod +x bazel-1.2.1-installer-linux-x86_64.sh

./bazel-1.2.1-installer-linux-x86_64.sh --prefix=$BAZEL_INSTALL_DIR

echo "Building lz4"
git clone https://github.com/lz4/lz4
pushd lz4
sudo make install
popd

echo "Building libzmq"
sudo apt remove libunwind-dev
sudo apt install -y \
    git build-essential libtool \
    pkg-config autotools-dev autoconf automake cmake \
    uuid-dev libpcre3-dev valgrind liblzma-dev
wget https://github.com/zeromq/libzmq/releases/download/v4.2.2/zeromq-4.2.2.tar.gz
tar -xvf zeromq-4.2.2.tar.gz
pushd zeromq-4.2.2
mkdir -p build
cd build
../configure
sudo make install -j$(nproc)
sudo ldconfig
popd

echo "Building czmq"
wget https://github.com/zeromq/czmq/releases/download/v4.2.0/czmq-4.2.0.tar.gz
tar -xvf czmq-4.2.0.tar.gz
pushd czmq-4.2.0
mkdir -p build
cd build
cmake ..
sudo make install
sudo ldconfig
popd

