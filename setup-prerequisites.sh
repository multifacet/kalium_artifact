#!/bin/bash

set -ex

BAZEL_INSTALL_DIR=$HOME/bazel

sudo apt update
sudo apt install wget curl zlib1g-dev


mkdir -p $BAZEL_INSTALL_DIR
wget https://github.com/bazelbuild/bazel/releases/download/1.2.1/bazel-1.2.1-installer-linux-x86_64.sh
chmod +x bazel-1.2.1-installer-linux-x86_64.sh

./bazel-1.2.1-installer-linux-x86_64.sh --prefix=$BAZEL_INSTALL_DIR

