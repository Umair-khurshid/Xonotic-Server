#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Xonotic Game Server - Quick Setup   ${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

if ! command -v docker &>/dev/null; then
  echo -e "${YELLOW}Docker is not installed.${NC}"
  echo "Install it first: https://www.docker.com/products/docker-desktop/"
  echo "Then run this script again."
  exit 1
fi

if ! docker info &>/dev/null; then
  echo -e "${YELLOW}Docker is installed but not running.${NC}"
  echo "Start Docker and try again."
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE="xonotic-server:local"

if [ ! -f "$SCRIPT_DIR/Dockerfile" ]; then
  echo -e "${YELLOW}Run this script from a clone of the Xonotic-Server repository.${NC}"
  exit 1
fi

if docker container inspect xonotic-server >/dev/null 2>&1; then
  echo "A container named xonotic-server already exists; refusing to replace it." >&2
  echo "Stop and remove it yourself only after backing up any data you need." >&2
  exit 1
fi

echo -e "${GREEN}[1/4] Building the verified server image...${NC}"
docker build --pull -t "$IMAGE" "$SCRIPT_DIR"

SERVER_NAME="Xonotic Server"
read -p "$(echo -e "${BOLD}Server name${NC} (press Enter for 'Xonotic Server'): ")" input
SERVER_NAME="${input:-$SERVER_NAME}"

JOIN_PASSWORD=""
read -s -p "$(echo -e "${BOLD}Player password${NC} (press Enter for a public server): ")" input
echo ""
JOIN_PASSWORD="$input"

RCON_PASSWORD=""
read -s -p "$(echo -e "${BOLD}RCON admin password${NC} (press Enter to disable RCON): ")" input
echo ""
RCON_PASSWORD="$input"

echo ""
echo -e "${GREEN}[2/4] Starting server...${NC}"

environment_args=(-e "XONOTIC_HOSTNAME=$SERVER_NAME")
if [ -n "$JOIN_PASSWORD" ]; then
  environment_args+=(-e "XONOTIC_JOIN_PASSWORD=$JOIN_PASSWORD")
fi
if [ -n "$RCON_PASSWORD" ]; then
  environment_args+=(-e "XONOTIC_RCON_PASSWORD=$RCON_PASSWORD")
fi

docker run -d \
  --name xonotic-server \
  --restart unless-stopped \
  --mount source=xonotic-data,target=/opt/Xonotic/data \
  -p 26000:26000/udp \
  "${environment_args[@]}" \
  "$IMAGE" \
  > /dev/null

echo -e "${GREEN}[3/4] Waiting for server to start...${NC}"
sleep 10

echo -e "${GREEN}[4/4] Done!${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}         Your Server Is Ready!          ${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

echo -e "  ${BOLD}Server name:${NC}  $SERVER_NAME"
echo -e "  ${BOLD}Connect at:${NC}   your-server-ip:26000"
echo ""

echo -e "  To connect:"
echo -e "    1. Open Xonotic"
echo -e "    2. Press ${BOLD}~${NC} key to open console"
echo -e "    3. Type: ${BOLD}connect your-server-ip:26000${NC}"
echo ""

echo -e "  Commands:"
echo -e "    Stop:      ${BOLD}docker stop xonotic-server${NC}"
echo -e "    View logs: ${BOLD}docker logs xonotic-server${NC}"
echo -e "    Remove:    ${BOLD}docker rm -f xonotic-server${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Script by Umair Khurshid             ${NC}"
echo -e "${CYAN}========================================${NC}"
