#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local expected=$1
  local file=$2
  grep -F -- "$expected" "$file" >/dev/null || fail "expected '$expected' in $file"
}

make_fake_docker() {
  local existing=$1
  mkdir -p "$WORK_DIR/bin"
  cat > "$WORK_DIR/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -eu
printf '%q ' "$@" >> "${FAKE_DOCKER_LOG:?}"
printf '\n' >> "${FAKE_DOCKER_LOG:?}"
case "${1:-}" in
  info|pull) exit 0 ;;
  container)
    if [[ "${2:-}" == "inspect" && "${FAKE_DOCKER_EXISTING:-0}" == "1" ]]; then
      exit 0
    fi
    exit 1
    ;;
  inspect) printf 'healthy\n'; exit 0 ;;
  run) printf 'container-id\n'; exit 0 ;;
esac
EOF
  chmod +x "$WORK_DIR/bin/docker"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$WORK_DIR/bin/sleep"
  chmod +x "$WORK_DIR/bin/sleep"
}

run_setup() {
  local existing=$1
  local work="$WORK_DIR/run-$existing"
  mkdir -p "$work"
  : > "$work/docker.log"
  (
    cd "$work"
    PATH="$WORK_DIR/bin:$PATH" \
    FAKE_DOCKER_LOG="$work/docker.log" \
    FAKE_DOCKER_EXISTING="$existing" \
    bash "$ROOT_DIR/setup.sh" <<< $'TDD Server\njoin-secret\nadmin-secret\n'
  ) > "$work/stdout" 2> "$work/stderr"
}

make_fake_docker 0
run_setup 0
assert_contains 'source=xonotic-data\,target=/opt/Xonotic/data' "$WORK_DIR/run-0/docker.log"
assert_contains 'XONOTIC_HOSTNAME=TDD\ Server' "$WORK_DIR/run-0/docker.log"
assert_contains 'XONOTIC_JOIN_PASSWORD=join-secret' "$WORK_DIR/run-0/docker.log"
assert_contains 'XONOTIC_RCON_PASSWORD=admin-secret' "$WORK_DIR/run-0/docker.log"
if grep -F -- '-p 26000:26000 ' "$WORK_DIR/run-0/docker.log" >/dev/null; then
  fail 'setup must not publish TCP port 26000'
fi
if grep -F -- 'admin-secret' "$WORK_DIR/run-0/stdout" >/dev/null; then
  fail 'setup must not print the RCON password'
fi

# setup.sh must wait for the Docker health check instead of a fixed sleep.
if ! grep -F -- 'inspect --format' "$WORK_DIR/run-0/docker.log" >/dev/null; then
  fail 'setup must poll the container health status'
fi

if run_setup 1; then
  fail 'setup must refuse to overwrite an existing server'
fi
assert_contains 'already exists' "$WORK_DIR/run-1/stderr"

echo 'PASS: setup behavior'
