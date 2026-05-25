FROM ubuntu:24.04 AS builder

LABEL maintainer="Umair Khurshid <umairkhurshid@protonmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV XONOTIC_DOWNLOAD_URL=http://dl.xonotic.org/xonotic-0.8.6.zip

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl unzip && \
    mkdir -p /opt && \
    curl -sSL "$XONOTIC_DOWNLOAD_URL" -o /opt/xonotic.zip && \
    unzip /opt/xonotic.zip -d /opt && \
    chmod +x /opt/Xonotic/server/server_linux.sh && \
    cp /opt/Xonotic/server/server.cfg /opt/Xonotic/data/

FROM ubuntu:24.04

LABEL maintainer="Umair Khurshid <umairkhurshid@protonmail.com>"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y libstdc++6 netcat-openbsd && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /opt/Xonotic /opt/Xonotic

RUN groupadd -r xonotic && \
    useradd -r -g xonotic -d /opt/Xonotic -s /sbin/nologin xonotic && \
    chown -R xonotic:xonotic /opt/Xonotic

WORKDIR /opt/Xonotic

USER xonotic

EXPOSE 26000/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD nc -z -u 127.0.0.1 26000 || exit 1

CMD ["/opt/Xonotic/server/server_linux.sh"]
