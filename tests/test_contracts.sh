#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require() {
  rg -q -- "$1" "$2" || fail "missing '$1' in $2"
}

forbid() {
  if rg -q -- "$1" "$2"; then
    fail "unexpected '$1' in $2"
  fi
}

require 'https://dl.xonotic.org/xonotic-0.8.6.zip' Dockerfile
require 'sha256sum -c' Dockerfile
require 'ENTRYPOINT \["/opt/Xonotic/server/entrypoint.sh"\]' Dockerfile
require 'libstdc\+\+6 nano' Dockerfile
require 'name: xonotic-data' docker-compose.yml
forbid '26000:26000"$' docker-compose.yml
require 'nano /opt/Xonotic/data/server.cfg' README.md
forbid 'nc -z -u' Dockerfile
require '\$\$process/comm' Dockerfile
forbid 'nc -z -u' tests/smoke.sh
forbid 'grep -q "xonotic"' tests/smoke.sh
require 'trap cleanup' tests/smoke.sh

echo 'PASS: deployment contracts'
