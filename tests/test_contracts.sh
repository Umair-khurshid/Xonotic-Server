#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require() {
  grep -Eq -- "$1" "$2" || fail "missing /$1/ in $2"
}

forbid() {
  if grep -Eq -- "$1" "$2"; then
    fail "unexpected /$1/ in $2"
  fi
}

# Every shell script must at least parse.
for script in setup.sh docker-entrypoint.sh tests/*.sh; do
  bash -n "$script" || fail "bash syntax error in $script"
done
sh -n docker-entrypoint.sh || fail 'sh syntax error in docker-entrypoint.sh'

# Dockerfile: pinned + checksum-verified download, non-root runtime, no editor.
require 'https://dl\.xonotic\.org/xonotic-0\.8\.6\.zip' Dockerfile
require 'sha256sum -c' Dockerfile
require '^USER xonotic$' Dockerfile
require 'org\.opencontainers\.image\.' Dockerfile
require 'ENTRYPOINT \["/opt/Xonotic/server/entrypoint\.sh"\]' Dockerfile
forbid 'nano' Dockerfile

# docker-compose: UDP only, hardened, persistent data volume.
require '26000:26000/udp' docker-compose.yml
forbid '26000:26000"' docker-compose.yml
require 'cap_drop' docker-compose.yml
require 'no-new-privileges:true' docker-compose.yml
require 'name: xonotic-data' docker-compose.yml

# The runtime image no longer ships an editor, so docs must not tell users to
# run one inside the container.
forbid 'nano' README.md

echo 'PASS: deployment contracts'
