#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# This is a best practice for shell scripts.
set -e

#
# === 1. Start Web Server ===
#
# Start the Caddy web server in the background (&).
# This serves the noVNC HTML/JS/CSS files on port 8080.
#
echo "Starting Caddy web server on :8080..."
caddy run --config /etc/caddy/Caddyfile &

#
# === 2. Start WebSocket Bridge ===
#
# Start websockify in the background (&).
# This creates a bridge between the browser's WebSocket connection
# and the VM's raw TCP VNC connection.
#
#   Browser (WebSocket) -> :6080 -> Websockify -> :5900 -> QEMU VNC
#
echo "Starting WebSocket proxy on :6080..."
websockify --web /sandbox/novnc 6080 127.0.0.1:5900 &

#
# === 3. Start the QEMU Virtual Machine ===
#
# This is the main foreground process. When QEMU exits,
# the script will end and the container will stop.
#
echo "Booting Windows VM..."
qemu-system-x86_64 \
    # --- Core Performance ---
    -enable-kvm \
    # (Tunable) Assign 4GB of RAM to the VM.
    -m 4G \
    # (Tunable) Assign 2 CPU cores to the VM.
    -smp 2 \

    # --- VNC Display ---
    # Start a VNC server on localhost (127.0.0.1) display :0 (port 5900).
    # It's only accessible *inside* the container, proxied by websockify.
    -vnc 127.0.0.1:0 \

    # --- Storage ---
    # Point to the disk image mounted at /sandbox/windows.qcow2.
    -drive file=/sandbox/windows.qcow2,format=qcow2 \
    #
    # *** THIS IS THE CORE SANDBOX FEATURE ***
    # All changes to the disk are written to a temporary overlay.
    # When QEMU exits, this overlay is *discarded*.
    # The original .qcow2 file is never modified.
    -snapshot \

    # --- Peripherals & Quality of Life ---
    # Enable a USB controller.
    -usb \
    # Use a 'usb-tablet' device for absolute mouse positioning.
    # This prevents "mouse drift" and a laggy cursor in the VNC client.
    -device usb-tablet \

    # --- Networking ---
    # Emulate an Intel e1000 network card (common, well-supported).
    -net nic,model=e1000 \
    # Use 'user-mode' networking. This is the simplest way to give the VM
    # internet access (via NAT) without requiring root privileges.
    -net user
