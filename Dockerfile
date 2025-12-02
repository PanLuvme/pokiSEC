FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install QEMU for BOTH x86 (Intel) and ARM (Mac)
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-system-arm \
    qemu-utils \
    qemu-efi-aarch64 \
    qemu-system-gui \
    python3 \
    python3-pip \
    novnc \
    websockify \
    supervisor \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Flask
RUN pip3 install --no-cache-dir flask

WORKDIR /sandbox
COPY app.py /app/app.py
COPY templates /app/templates
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
