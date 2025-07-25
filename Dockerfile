# Download and prepare Xonotic
FROM ubuntu:24.04 AS builder

LABEL maintainer="Umair Khurshid <umairkhurshid[@]protonmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV XONOTIC_DOWNLOAD_URL=http://dl.xonotic.org/xonotic-0.8.6.zip

# Update and install only required build-time tools
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl unzip && \
    mkdir -p /opt && \
    curl -sSL "$XONOTIC_DOWNLOAD_URL" -o /opt/xonotic.zip && \
    unzip /opt/xonotic.zip -d /opt && \
    chmod +x /opt/Xonotic/server/server_linux.sh && \
    cp /opt/Xonotic/server/server.cfg /opt/Xonotic/data/

# Runtime Image
FROM ubuntu:24.04

LABEL maintainer="Umair Khurshid <umairkhurshid@protonmail.com>"

# Update base system to patch CVEs
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y libstdc++6 && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy Necessary Runtime Files
COPY --from=builder /opt/Xonotic /opt/Xonotic

WORKDIR /opt/Xonotic

# Expose default UDP port
EXPOSE 26000/udp
