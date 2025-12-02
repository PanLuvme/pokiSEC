FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install QEMU, KVM, and Python/Flask dependencies
RUN apt-get update && apt-get install -y \
    qemu-system-x86 \
    qemu-utils \
    python3 \
    python3-pip \
    novnc \
    websockify \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Flask
RUN pip3 install flask

# 3. Create Sandbox Directory
WORKDIR /sandbox

# 4. Copy your Application Code
COPY app.py /app/app.py
COPY templates /app/templates
COPY entrypoint.sh /entrypoint.sh

# 5. Make entrypoint executable
RUN chmod +x /entrypoint.sh

# 6. Expose Port 8080 (Used by BOTH Flask and NoVNC)
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
