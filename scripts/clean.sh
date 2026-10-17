#!/bin/sh
# Removes dangling images and build cache, then reports disk usage before and after.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

info "docker disk usage before:"
docker system df

docker image prune --force | tail -n 1
docker builder prune --force | tail -n 1

info "docker disk usage after:"
docker system df
