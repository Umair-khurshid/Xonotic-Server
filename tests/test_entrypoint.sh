#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
CONFIG="$WORK_DIR/server.cfg"

printf '// existing setting\n' > "$CONFIG"

XONOTIC_CONFIG_PATH="$CONFIG" \
XONOTIC_HOSTNAME='TDD "Server"; quit' \
XONOTIC_JOIN_PASSWORD='join; secret' \
XONOTIC_RCON_PASSWORD='admin\\secret' \
  sh "$ROOT_DIR/docker-entrypoint.sh" /bin/true

grep -F -- 'hostname "TDD \\"Server\\"; quit"' "$CONFIG" >/dev/null
grep -F -- 'password "join; secret"' "$CONFIG" >/dev/null
grep -F -- 'rcon_password "admin' "$CONFIG" >/dev/null
[ "$(grep -Fc '// BEGIN CODEX MANAGED SETTINGS' "$CONFIG")" = 1 ]

XONOTIC_CONFIG_PATH="$CONFIG" \
XONOTIC_HOSTNAME='Replacement' \
  sh "$ROOT_DIR/docker-entrypoint.sh" /bin/true

grep -F -- 'hostname "Replacement"' "$CONFIG" >/dev/null
[ "$(grep -Fc '// BEGIN CODEX MANAGED SETTINGS' "$CONFIG")" = 1 ]
if grep -F -- 'join; secret' "$CONFIG" >/dev/null; then
  echo 'FAIL: stale managed settings were retained' >&2
  exit 1
fi

echo 'PASS: entrypoint config generation'
