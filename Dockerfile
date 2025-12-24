FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    qemu-system \
    qemu-utils \
    genisoimage \
    curl \
    git \
    novnc \
    websockify \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install flask

RUN mkdir -p /data /payloads /templates

COPY app.py /app/
COPY entrypoint.sh /app/
COPY templates/ /app/templates/

RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]
