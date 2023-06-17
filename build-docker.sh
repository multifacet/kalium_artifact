#!/bin/bash

set -ex

mkdir -p build

docker build -t dsirone/kalium_prereq:build .

docker create --name buildoutput dsirone/kalium_prereq:build echo

docker cp buildoutput:/build/bin/ ./build/

docker rm buildoutput
