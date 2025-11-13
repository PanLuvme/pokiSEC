# Use a stable, common base image. Ubuntu 22.04 is a good LTS choice.
FROM ubuntu:22.04

# Set environment variable to prevent apt-get from hanging on interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

#
# === Install Core Dependencies ===
#
# We run all installs in a single RUN layer to reduce image size.
# - `rm -rf /var/lib/apt/lists/*` cleans up apt cache, further reducing size.
#
RUN apt-get update && apt-get install -y \
    # --- QEMU/KVM ---
    qemu-system-x86 \
    qemu-utils \
    # --- Web Server ---
    caddy \
    # --- VNC & WebSocket Bridge ---
    websockify \
    curl \
    && rm -rf /var/lib/apt/lists/*

#
# === Install noVNC (Web-based VNC Client) ===
#
# This creates a directory for the web files, downloads the latest noVNC release,
# and extracts it. This will be the front-end website.
#
RUN mkdir -p /sandbox/novnc
RUN curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | \
    tar -zxv --strip-components=1 -C /sandbox/novnc

#
# === Configure Caddy Web Server ===
#
# Caddy is a simple, modern web server. We write its config file here.
# This Caddyfile does two things:
#
# 1. `:8080` - Serves all content on port 8080.
# 2. `root * /sandbox/novnc` - Sets the web root to our noVNC files.
# 3. `file_server` - Enables serving those static files.
# 4. `reverse_proxy /websockify 127.0.0.1:6080` - This is the crucial part.
#    It proxies all requests from `http://.../websockify` to the
#    internal websockify service (which we start in `start.sh`).
#
RUN echo ':8080 {\n\
    root * /sandbox/novnc\n\
    file_server\n\
    reverse_proxy /websockify 127.0.0.1:6080\n\
}' > /etc/caddy/Caddyfile

#
# === Final Setup ===
#
# Set the working directory for the container.
WORKDIR /sandbox

# Copy the entrypoint script into the container and make it executable.
COPY start.sh .
RUN chmod +x start.sh

# Expose port 8080. This is documentation for the user and for
# inter-container networking. You still must use `docker run -p 8080:8080`.
EXPOSE 8080

# Define the default command to run when the container starts.
CMD ["./start.sh"]
