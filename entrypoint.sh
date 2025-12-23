#!/bin/bash
set -e

IMAGE_PATH="/sandbox/windows.qcow2"
ARCH=$(uname -m)

# === STAGE 1: SETUP (Flask) ===
if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ No Windows image found."
    echo "🚀 Starting Web Uploader on port 8080..."
    python3 /app/app.py
fi

# === STAGE 2: RUN ===
echo "🔥 Starting Windows Sandbox on architecture: $ARCH"

# Start NoVNC in background
/usr/share/novnc/utils/launch.sh --vnc localhost:5900 --listen 8080 &

if [ "$ARCH" == "aarch64" ]; then
    # === MAC M1/M2/M3 (ARM) MODE ===
    echo "🍎 Mac/ARM detected. Using Software Emulation (TCG)..."
    echo "⚠️  NOTE: Performance will be slower on Mac Docker due to lack of nested virtualization."
    
    # FIX: Removed "-accel kvm" and changed cpu to "max" for best emulation speed
    qemu-system-aarch64 \
        -nographic \
        -M virt,highmem=off \
        -cpu max \
        -m 4G \
        -smp 4 \
        -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
        -device ramfb \
        -device qemu-xhci \
        -device usb-kbd \
        -device usb-tablet \
        -drive file=${IMAGE_PATH},format=qcow2,if=virtio \
        -vnc :0

elif [ "$ARCH" == "x86_64" ]; then
    # === INTEL/AMD MODE (Linux/Windows) ===
    echo "💻 Intel/AMD detected. Using Native KVM..."
    
    qemu-system-x86_64 \
        -m 4G \
        -cpu host \
        -smp 2 \
        -enable-kvm \
        -drive file=${IMAGE_PATH},format=qcow2 \
        -vnc :0 \
        -net nic -net user \
        -usb -device usb-tablet
else
    echo "❌ Unsupported Architecture: $ARCH"
    exit 1
fi
