FROM ubuntu:24.04 AS builder

LABEL maintainer="Umair Khurshid <umairkhurshid@protonmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
ARG XONOTIC_DOWNLOAD_URL=https://dl.xonotic.org/xonotic-0.8.6.zip
ARG XONOTIC_DOWNLOAD_SHA256=50850f8d800e7499722f6ea61e478e96464a375494b5a24da93aa0598cbe964d

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl unzip && \
    mkdir -p /opt && \
    curl --fail --show-error --location --proto '=https' --tlsv1.2 "$XONOTIC_DOWNLOAD_URL" -o /opt/xonotic.zip && \
    echo "$XONOTIC_DOWNLOAD_SHA256  /opt/xonotic.zip" | sha256sum -c - && \
    unzip -q /opt/xonotic.zip -d /opt && \
    chmod +x /opt/Xonotic/server/server_linux.sh && \
    cp /opt/Xonotic/server/server.cfg /opt/Xonotic/data/ && \
    rm -rf /var/lib/apt/lists/* /opt/xonotic.zip

FROM ubuntu:24.04

LABEL maintainer="Umair Khurshid <umairkhurshid@protonmail.com>"

RUN apt-get update && \
    apt-get install -y --no-install-recommends libstdc++6 nano && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /opt/Xonotic /opt/Xonotic
COPY docker-entrypoint.sh /opt/Xonotic/server/entrypoint.sh

RUN groupadd -r xonotic && \
    useradd -r -g xonotic -d /opt/Xonotic -s /sbin/nologin xonotic && \
    chmod +x /opt/Xonotic/server/entrypoint.sh && \
    chown -R xonotic:xonotic /opt/Xonotic

WORKDIR /opt/Xonotic

USER xonotic

EXPOSE 26000/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD ["/bin/sh", "-ec", "for process in /proc/[0-9]*; do [ -r \"$$process/comm\" ] || continue; IFS= read -r name < \"$$process/comm\"; case \"$$name\" in xonotic*|darkplaces*) exit 0 ;; esac; done; exit 1"]

ENTRYPOINT ["/opt/Xonotic/server/entrypoint.sh"]
CMD ["/opt/Xonotic/server/server_linux.sh"]
