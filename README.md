# Xonotic Gaming Server

[![CI](https://github.com/Umair-khurshid/Xonotic-Server/actions/workflows/ci.yml/badge.svg)](https://github.com/Umair-khurshid/Xonotic-Server/actions/workflows/ci.yml)

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
Xonotic archive checksum, creates the `xonotic-data` volume, starts the server,
and waits for its health check to pass. It will never replace an existing
`xonotic-server` container.

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

### Keeping passwords out of the environment

Inline `XONOTIC_*` values are visible to anyone who can run `docker inspect` or
`ps`. To avoid that, point the `*_FILE` variables at a mounted secret instead.
For example, with Docker Compose:

```yaml
secrets:
  rcon_password:
    file: ./rcon_password.txt

services:
  xonotic-server:
    environment:
      XONOTIC_RCON_PASSWORD_FILE: /run/secrets/rcon_password
    secrets:
      - rcon_password
```

The file contents take precedence over the inline value, and a missing or
unreadable file makes the container fail fast rather than start unconfigured.

The container writes these values as an escaped, managed block in
`/opt/Xonotic/data/server.cfg`. For additional gameplay options, use
[`server.cfg.example`](server.cfg.example) as a reference and edit the file
from the host (the image does not ship an editor):

```bash
docker cp xonotic-server:/opt/Xonotic/data/server.cfg ./server.cfg
# edit ./server.cfg with your preferred local editor
docker cp ./server.cfg xonotic-server:/opt/Xonotic/data/server.cfg
docker restart xonotic-server
```

Settings inside the `// BEGIN MANAGED SETTINGS` block are regenerated from the
environment on every start; edit them there instead of in the file.

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

Restore it only after stopping the server, using the same volume name:

```bash
docker stop xonotic-server
docker run --rm \
  --mount source=xonotic-data,target=/data \
  --mount type=bind,source="$(pwd)",target=/backup,readonly \
  ubuntu:24.04 sh -c 'rm -rf /data/* && tar xzf /backup/xonotic-backup.tar.gz -C /data'
docker start xonotic-server
```

## Security notes

- The container runs as the unprivileged `xonotic` user.
- `docker-compose.yml` drops all Linux capabilities, sets
  `no-new-privileges`, and mounts `/tmp` as `tmpfs`. If you start the container
  with a raw `docker run`, add `--cap-drop=ALL --security-opt
  no-new-privileges` yourself.
- The Xonotic archive is downloaded over HTTPS and verified against a pinned
  SHA-256 checksum during the build.

## Platform support

Xonotic 0.8.6 ships a 64-bit x86 (`amd64`) server binary only. The image builds
on other architectures but the dedicated server will not run on `arm64`/`arm`.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE). Xonotic itself is licensed separately.
