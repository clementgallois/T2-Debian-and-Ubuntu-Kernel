#!/bin/bash

set -eu -o pipefail

DOCKER_IMAGE=kalilinux/kali-rolling:latest

docker pull ${DOCKER_IMAGE}
docker run \
  -t \
  --rm \
  -v "$(pwd)":/workspace:Z \
  ${DOCKER_IMAGE} \
  /bin/bash -c 'cd /workspace && ./build.sh'