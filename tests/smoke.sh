#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-xonotic-server:local}"
CONTAINER_NAME="xonotic-smoke-$(date +%s%N)"

cleanup() {
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT HUP INT TERM

echo "=== Xonotic Server Smoke Test ==="
echo "Image: $IMAGE"

echo ""
echo "1. Starting container..."
docker run -d --name "$CONTAINER_NAME" -p 127.0.0.1::26000/udp "$IMAGE"

echo "2. Waiting for the health check..."
for _ in $(seq 1 30); do
  health=$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_NAME")
  case "$health" in
    healthy) break ;;
    unhealthy)
      echo "   FAIL: Container health check reported unhealthy"
      docker logs "$CONTAINER_NAME"
      exit 1
      ;;
  esac
  sleep 1
done

echo "3. Checking container health..."
if [ "$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_NAME")" = "healthy" ]; then
  echo "   PASS: Container health check passed"
else
  echo "   FAIL: Container did not become healthy"
  docker logs "$CONTAINER_NAME"
  exit 1
fi

echo "4. Checking server process..."
if docker top "$CONTAINER_NAME" -eo pid,comm | awk 'tolower($2) ~ /^(xonotic|darkplaces)/ { found = 1 } END { exit !found }'; then
  echo "   PASS: Server process found"
else
  echo "   FAIL: Server process not found"
  docker logs "$CONTAINER_NAME"
  exit 1
fi

echo "5. Checking published UDP port..."
if docker port "$CONTAINER_NAME" 26000/udp | grep -Eq '^127\.0\.0\.1:[0-9]+$'; then
  echo "   PASS: UDP port 26000 is published"
else
  echo "   FAIL: UDP port 26000 is not published"
  docker logs "$CONTAINER_NAME"
  exit 1
fi

echo ""
echo "=== All smoke tests passed ==="
