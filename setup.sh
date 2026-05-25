#!/usr/bin/env bash
set -e

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

echo -e "${GREEN}[1/4] Pulling server image...${NC}"
docker pull umair101/xonotic-server:v1.1

SERVER_NAME="Xonotic Server"
read -p "$(echo -e "${BOLD}Server name${NC} (press Enter for 'Xonotic Server'): ")" input
SERVER_NAME="${input:-$SERVER_NAME}"

SERVER_PASSWORD=""
read -s -p "$(echo -e "${BOLD}Server password${NC} (press Enter for no password): ")" input
echo ""
SERVER_PASSWORD="$input"

if [ -n "$SERVER_PASSWORD" ]; then
  PASSWORD_CFG="rcon_password \"$SERVER_PASSWORD\""
else
  PASSWORD_CFG="# rcon_password \"\""
fi

echo ""
echo -e "${GREEN}[2/4] Starting server...${NC}"

docker rm -f xonotic-server 2>/dev/null || true

docker run -d \
  --name xonotic-server \
  --restart unless-stopped \
  -p 26000:26000/udp \
  -p 26000:26000 \
  umair101/xonotic-server:v1.1 \
  +serverconfig "hostname \"$SERVER_NAME\"; $PASSWORD_CFG" \
  > /dev/null

echo -e "${GREEN}[3/4] Waiting for server to start...${NC}"
sleep 10

echo -e "${GREEN}[4/4] Done!${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}         Your Server Is Ready!          ${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

if command -v curl &>/dev/null; then
  PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "localhost")
else
  PUBLIC_IP="your-server-ip"
fi

echo -e "  ${BOLD}Server name:${NC}  $SERVER_NAME"
echo -e "  ${BOLD}Connect at:${NC}   ${PUBLIC_IP}:26000"
echo ""

echo -e "  To connect:"
echo -e "    1. Open Xonotic"
echo -e "    2. Press ${BOLD}~${NC} key to open console"
echo -e "    3. Type: ${BOLD}connect ${PUBLIC_IP}:26000${NC}"
echo ""

if [ -n "$SERVER_PASSWORD" ]; then
  echo -e "  RCON password: ${BOLD}$SERVER_PASSWORD${NC}"
  echo ""
fi

echo -e "  Commands:"
echo -e "    Stop:      ${BOLD}docker stop xonotic-server${NC}"
echo -e "    View logs: ${BOLD}docker logs xonotic-server${NC}"
echo -e "    Remove:    ${BOLD}docker rm -f xonotic-server${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Script by Umair Khurshid             ${NC}"
echo -e "${CYAN}========================================${NC}"
