#!/bin/bash
set -e

# Define paths
IMAGE_PATH="/sandbox/windows.qcow2"

# === STAGE 1: SETUP (Flask) ===
if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ No Windows image found."
    echo "🚀 Starting Web Uploader on port 8080..."
    
    # Run Flask. It will handle upload -> convert -> then EXIT when done.
    python3 /app/app.py
    
    echo "✅ Setup complete. Image is ready."
fi

# === STAGE 2: RUN (QEMU + NoVNC) ===
echo "🔥 Starting Windows Sandbox..."

# Start NoVNC (Web Interface) pointing to localhost:5900 (VNC)
# We launch it in background so we can run QEMU
/usr/share/novnc/utils/launch.sh --vnc localhost:5900 --listen 8080 &

# Start QEMU (The VM)
qemu-system-x86_64 \
    -m 4G \
    -cpu host \
    -smp 2 \
    -enable-kvm \
    -drive file=${IMAGE_PATH},format=qcow2 \
    -vnc :0 \
    -net nic -net user
