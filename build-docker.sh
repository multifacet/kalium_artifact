#!/bin/bash

set -ex

function usage() {
   echo "./build-docker.sh <kalium controller hostname>"
}

if [ -z "$1" ]; then
        usage
        exit 1
fi

mkdir -p build

docker build --build-arg controllerHost=$1 -t dsirone/kalium_prereq:build .

docker create --name buildoutput dsirone/kalium_prereq:build echo

docker cp buildoutput:/build/bin/ ./build/

docker rm buildoutput
