#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
CONFIG="$WORK_DIR/server.cfg"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  grep -F -- "$1" "$2" >/dev/null || fail "expected '$1' in $2"
}

assert_absent() {
  if grep -F -- "$1" "$2" >/dev/null; then
    fail "unexpected '$1' in $2"
  fi
}

printf '// existing setting\n' > "$CONFIG"

XONOTIC_CONFIG_PATH="$CONFIG" \
XONOTIC_HOSTNAME='TDD "Server"; quit' \
XONOTIC_JOIN_PASSWORD='join; secret' \
XONOTIC_RCON_PASSWORD='admin\secret' \
  sh "$ROOT_DIR/docker-entrypoint.sh" /bin/true

assert_contains 'hostname "TDD \"Server\"; quit"' "$CONFIG"
assert_contains 'password "join; secret"' "$CONFIG"
assert_contains 'rcon_password "admin\\secret"' "$CONFIG"
[ "$(grep -Fc '// BEGIN MANAGED SETTINGS' "$CONFIG")" = 1 ] \
  || fail 'managed settings block was not written exactly once'

XONOTIC_CONFIG_PATH="$CONFIG" \
XONOTIC_HOSTNAME='Replacement' \
  sh "$ROOT_DIR/docker-entrypoint.sh" /bin/true

assert_contains 'hostname "Replacement"' "$CONFIG"
[ "$(grep -Fc '// BEGIN MANAGED SETTINGS' "$CONFIG")" = 1 ] \
  || fail 'managed settings block was duplicated'
assert_absent 'join; secret' "$CONFIG"

# Secret files take precedence over inline environment values, and the file
# path itself must never be written into the generated config.
SECRET_DIR="$WORK_DIR/secrets"
mkdir -p "$SECRET_DIR"
printf 'File Hostname\n' > "$SECRET_DIR/hostname"
printf 'file-join-secret\n' > "$SECRET_DIR/join"
printf 'file-rcon-secret\n' > "$SECRET_DIR/rcon"
CONFIG_FILES="$WORK_DIR/server-files.cfg"
printf '// existing setting\n' > "$CONFIG_FILES"

XONOTIC_CONFIG_PATH="$CONFIG_FILES" \
XONOTIC_HOSTNAME='env-hostname' \
XONOTIC_JOIN_PASSWORD='env-join-secret' \
XONOTIC_HOSTNAME_FILE="$SECRET_DIR/hostname" \
XONOTIC_JOIN_PASSWORD_FILE="$SECRET_DIR/join" \
XONOTIC_RCON_PASSWORD_FILE="$SECRET_DIR/rcon" \
  sh "$ROOT_DIR/docker-entrypoint.sh" /bin/true

assert_contains 'hostname "File Hostname"' "$CONFIG_FILES"
assert_contains 'password "file-join-secret"' "$CONFIG_FILES"
assert_contains 'rcon_password "file-rcon-secret"' "$CONFIG_FILES"
assert_absent 'env-hostname' "$CONFIG_FILES"
assert_absent 'env-join-secret' "$CONFIG_FILES"
assert_absent "$SECRET_DIR" "$CONFIG_FILES"

# An unreadable secret file must fail fast rather than silently ignoring it.
CONFIG_MISSING="$WORK_DIR/server-missing.cfg"
if XONOTIC_CONFIG_PATH="$CONFIG_MISSING" \
   XONOTIC_RCON_PASSWORD_FILE="$SECRET_DIR/does-not-exist" \
     sh "$ROOT_DIR/docker-entrypoint.sh" /bin/true >/dev/null 2>&1; then
  fail 'unreadable secret file did not fail the entrypoint'
fi

# Pre-existing "CODEX" managed blocks from earlier releases are migrated away
# while unmanaged settings are preserved.
CONFIG_LEGACY="$WORK_DIR/server-legacy.cfg"
cat > "$CONFIG_LEGACY" <<'EOF'
// keep me
// BEGIN CODEX MANAGED SETTINGS
hostname "old-codex-host"
rcon_password "old-codex-secret"
// END CODEX MANAGED SETTINGS
EOF

XONOTIC_CONFIG_PATH="$CONFIG_LEGACY" \
XONOTIC_HOSTNAME='Fresh Host' \
  sh "$ROOT_DIR/docker-entrypoint.sh" /bin/true

assert_contains '// keep me' "$CONFIG_LEGACY"
assert_contains 'hostname "Fresh Host"' "$CONFIG_LEGACY"
assert_absent 'CODEX' "$CONFIG_LEGACY"
assert_absent 'old-codex-host' "$CONFIG_LEGACY"
assert_absent 'old-codex-secret' "$CONFIG_LEGACY"

echo 'PASS: entrypoint config generation'
