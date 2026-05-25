
# Xonotic Gaming Server

This repository helps you host your own Xonotic game server using Docker. No technical experience needed — just follow the steps below.

---

## Easy Setup (2 Minutes)

### 1. Install Docker

Download and install Docker from [docker.com](https://www.docker.com/products/docker-desktop/). 

### 2. Start Your Server

**Easiest way:** Download and run the setup script:

```bash
curl -O https://raw.githubusercontent.com/Umair-khurshid/Xonotic-Server/main/setup.sh
bash setup.sh
```

**Or** open a terminal (Command Prompt on Windows, Terminal on Mac/Linux) and run:

```bash
docker run -d \
  --name xonotic-server \
  --restart unless-stopped \
  -p 26000:26000/udp \
  -p 26000:26000 \
  umair101/xonotic-server:v1.1
```

That's it. Your server is now running.

### 3. Connect and Play

Open Xonotic on your computer, press the **`~`** key to open the console, and type:

```
connect your-server-ip:26000
```

Replace `your-server-ip` with your IP address.

---

## Stop or Restart

To stop your server:

```bash
docker stop xonotic-server
```

To start it again later:

```bash
docker start xonotic-server
```

To remove it completely:

```bash
docker rm xonotic-server
```

---

## Change Server Settings

1. Run this command to edit settings:
   ```bash
   docker exec -it xonotic-server nano /opt/Xonotic/data/server.cfg
   ```
2. Change things like the server name, game mode, or password.
3. Press `Ctrl+X`, then `Y`, then `Enter` to save.
4. Restart the server:
   ```bash
   docker restart xonotic-server
   ```

---

## Keep Your Data Safe (Backups)

Your server data (scores, settings, maps) is stored safely. To back it up:

```bash
docker run --rm -v xonotic-data:/data -v .:/backup ubuntu tar czf /backup/xonotic-backup.tar.gz -C /data .
```

This creates a file called `xonotic-backup.tar.gz` in your current folder.

---

## Need Help?

If something isn't working, make sure Docker is running and you've followed the steps above in order. Still stuck? Open an issue on GitHub.

---

[![Buy Me a Coffee](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=☕&slug=umairkhurshid&button_colour=BD5FFF&font_colour=ffffff&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00)](https://www.buymeacoffee.com/umairkhurshid)
