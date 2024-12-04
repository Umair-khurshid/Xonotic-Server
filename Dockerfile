# Use Ubuntu as the base image
FROM ubuntu:latest

# Maintainer information
LABEL maintainer="Umair Khurshid <umairkhurshid@protonmail.com>"

# Environment variables
ENV XONOTIC_DOWNLOAD_URL=http://dl.xonotic.org/xonotic-0.8.6.zip

# Install dependencies
RUN apt-get update && \
    apt-get install -y bash curl wget unzip zip libstdc++6 && \
    wget $XONOTIC_DOWNLOAD_URL -q -O /opt/xonotic.zip && \
    unzip /opt/xonotic.zip -d /opt && \
    rm /opt/xonotic.zip && \
    chmod +x /opt/Xonotic/server/server_linux.sh && \
    cp /opt/Xonotic/server/server.cfg /opt/Xonotic/data/ && \
    mv /opt/Xonotic/server/server_linux.sh /opt/Xonotic/ && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Set the working directory
WORKDIR /opt/Xonotic

# Expose the default UDP port
EXPOSE 26000/udp

# Start the Xonotic server
CMD ["/opt/Xonotic/server_linux.sh"]

