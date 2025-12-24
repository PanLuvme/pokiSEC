#!/bin/bash

OS_IMAGE="/data/windows.qcow2"
PAYLOAD_DIR="/payloads_staging"
PAYLOAD_ISO="/tmp/payloads.iso"
SIGNAL_FILE="/tmp/boot_signal"

# Start the Web Interface
python3 /app/app.py &

# Wait for the interface to signal boot
while [ ! -f "$SIGNAL_FILE" ]; do
    sleep 1
done
sleep 2

# default disk args
DISK_ARGS="-drive file=${OS_IMAGE},format=qcow2"

# If payloads exist, bundle them and add the CD-ROM drive
if [ "$(ls -A $PAYLOAD_DIR)" ]; then
    genisoimage -R -J -o "$PAYLOAD_ISO" "$PAYLOAD_DIR"
    DISK_ARGS="$DISK_ARGS -drive file=$PAYLOAD_ISO,media=cdrom,readonly=on"
fi

ARCH=$(uname -m)

# Start VNC Server
websockify -D --web=/usr/share/novnc/ 8080 localhost:5900

if [ "$ARCH" == "aarch64" ]; then
    # --- ARM64 CONFIG (MAC M1/M2/M3) ---
    qemu-system-aarch64 \
        -M virt \
        -accel tcg \
        -cpu max \
        -smp 4 \
        -m 4G \
        -device ramfb \
        -device qemu-xhci \
        -device usb-kbd \
        -device usb-tablet \
        $DISK_ARGS \
        -vnc :0 \
        -nographic

elif [ "$ARCH" == "x86_64" ]; then
    # --- INTEL/AMD CONFIG ---
    qemu-system-x86_64 \
        -cpu host \
        -enable-kvm \
        -m 4G \
        -smp 4 \
        -vga std \
        $DISK_ARGS \
        -vnc :0 \
        -nographic
fi
