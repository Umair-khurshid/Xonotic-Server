#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-umair101/xonotic-server:v1.1}"
CONTAINER_NAME="xonotic-smoke-$(date +%s)"

echo "=== Xonotic Server Smoke Test ==="
echo "Image: $IMAGE"

echo ""
echo "1. Starting container..."
docker run -d --name "$CONTAINER_NAME" "$IMAGE"

echo "2. Waiting for server to initialize (15s)..."
sleep 15

echo "3. Checking container status..."
if docker ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}" | grep -q "Up"; then
  echo "   PASS: Container is running"
else
  echo "   FAIL: Container is not running"
  docker logs "$CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME" 2>/dev/null
  exit 1
fi

echo "4. Checking server process..."
if docker exec "$CONTAINER_NAME" ps aux | grep -q "xonotic"; then
  echo "   PASS: Server process found"
else
  echo "   FAIL: Server process not found"
  docker logs "$CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME" 2>/dev/null
  exit 1
fi

echo "5. Checking UDP port..."
if docker exec "$CONTAINER_NAME" nc -z -u 127.0.0.1 26000; then
  echo "   PASS: UDP port 26000 is open"
else
  echo "   FAIL: UDP port 26000 is not reachable"
  docker logs "$CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME" 2>/dev/null
  exit 1
fi

echo ""
echo "=== All smoke tests passed ==="

docker stop "$CONTAINER_NAME"
docker rm "$CONTAINER_NAME"