
# Xonotic Gaming Server Docker

This repository contains a `Dockerfile` to easily set up and run a Xonotic gaming server using Docker. Xonotic is a fast-paced first-person shooter that you can host and play online with friends.

## Requirements

- Make sure Docker is installed on your system
  
## How to Use

### Step 1: Pull the Docker Image

Just pull docker image:

```
docker pull umair101/xonotic-server:latest
```
Alternatively, you can also build from the Dockerfile by cloning this repo.

### Step 2: Run the Docker Container

Once you have the you can run the Xonotic server with this command:

```bash
docker run -d --name xonotic-server -p 26000:26000/udp -p 26000:26000 umair101/xonotic-server:latest
```
#### Explanation:
- `-d` Runs the container in detached mode (background).
- `--name xonotic-server` Gives your container a name (you can change it).
- `-p 26000:26000/udp` Exposes the default UDP port for Xonotic (port 26000).
- `-p 26000:26000` Ensures the TCP port is also mapped if needed (may depend on your server setup).
- `umair101/xonotic-server:latest` Specifies the image to use.

### Step 3: Connect to Your Server

Once the server is up and running, you can connect to it from your Xonotic game client using the your IP address:

```
<Your_Server_IP>:26000
```

### Step 4: Stop the Server

To stop the server, run the following command:

```bash
docker stop xonotic-server
```

To remove the container after stopping it:

```bash
docker rm xonotic-server
```

### Step 5: Customize the Server

You can customize the Xonotic server by editing the configuration file `server.cfg` located in the `/opt/Xonotic/data/` directory. To do this:

1. **Access the Container**:
   ```bash
   docker exec -it xonotic-server bash
   ```

2. **Edit the Configuration**:
   Edit the `server.cfg` file using a text editor inside the container:
   ```bash
   nvim /opt/Xonotic/data/server.cfg
   ```

3. **Restart the Server** to apply changes:
   ```bash
   docker restart xonotic-server
   ```

## Additional Notes

- **Persistence**:
 By default, the container will not store persistent data. If you want to preserve server data (e.g., configuration, maps, etc.), mount a host directory as a volume:
  ```bash
  docker run -d --name xonotic-server -p 26000:26000/udp -v /path/to/your/server/data:/opt/Xonotic/data xonotic-server
  ```

