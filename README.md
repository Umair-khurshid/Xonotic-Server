# Xonotic Gaming Server

Run a private or public Xonotic server with Docker. The server listens on UDP
port `26000` and stores its configuration and runtime data in the persistent
`xonotic-data` Docker volume.

## Quick start

Install [Docker](https://www.docker.com/products/docker-desktop/), then clone
this repository and run the interactive setup:

```bash
git clone https://github.com/Umair-khurshid/Xonotic-Server.git
cd Xonotic-Server
bash setup.sh
```

The script builds the image from this checked-out source, verifies the pinned
Xonotic archive checksum, creates the `xonotic-data` volume, and starts the
server. It will never replace an existing `xonotic-server` container.

To use Docker Compose instead:

```bash
docker compose up -d --build
```

## Connect and network setup

Open the Xonotic console with `~` and enter:

```
connect your-server-ip:26000
```

For players outside your local network, allow and forward **UDP 26000** from
your firewall/router to the Docker host. A public address may not be available
behind CGNAT.

## Configure the server

Copy the environment template and set only the options you need:

```bash
cp .env.example .env
```

- `XONOTIC_HOSTNAME` sets the server-list name.
- `XONOTIC_JOIN_PASSWORD` restricts players joining the server.
- `XONOTIC_RCON_PASSWORD` enables remote administration. Keep this long and
  secret; it is not a player password.

Restart after changing `.env`:

```bash
docker compose up -d
```

The container writes these values as an escaped, managed block in
`/opt/Xonotic/data/server.cfg`. For additional gameplay options, use
[`server.cfg.example`](server.cfg.example) as a reference and edit the file:

```bash
docker exec -it xonotic-server nano /opt/Xonotic/data/server.cfg
docker restart xonotic-server
```

## Operations

```bash
docker compose logs -f
docker compose stop
docker compose start
docker compose down
```

`docker compose down` keeps the data volume. To intentionally remove all
server data, use `docker volume rm xonotic-data` after stopping the server.

## Backups

Create a compressed backup in the current directory:

```bash
docker run --rm \
  --mount source=xonotic-data,target=/data,readonly \
  --mount type=bind,source="$(pwd)",target=/backup \
  ubuntu:24.04 tar czf /backup/xonotic-backup.tar.gz -C /data .
```

Restore it only after stopping the server, using the same volume name.

## Verify an image

After building with Compose or `setup.sh`, run:

```bash
bash tests/smoke.sh
```

The smoke test requires Docker and confirms the server becomes healthy, its
game process exists, and UDP port 26000 is published.
