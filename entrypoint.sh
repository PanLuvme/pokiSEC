#!/bin/bash
set -e

IMAGE_PATH="/sandbox/windows.qcow2"
ARCH=$(uname -m)

if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ No Windows image found."
    echo "🚀 Starting Web Uploader on port 8080..."
    python3 /app/app.py
fi

echo "🔥 Starting Windows Sandbox on architecture: $ARCH"

websockify --web=/usr/share/novnc --wrap-mode=ignore 8080 localhost:5900 &

if [ "$ARCH" == "aarch64" ]; then
    
    qemu-system-aarch64 \
        -nographic \
        -M virt,highmem=on \
        -cpu max \
        -accel tcg \
        -m 4G \
        -smp 4 \
        -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
        -device ramfb \
        -device qemu-xhci \
        -device usb-kbd \
        -device usb-tablet \
        -drive file=${IMAGE_PATH},format=qcow2,if=none,id=boot \
        -device usb-storage,drive=boot \
        -vnc :0

elif [ "$ARCH" == "x86_64" ]; then
    
    qemu-system-x86_64 \
        -m 4G \
        -cpu host \
        -smp 2 \
        -enable-kvm \
        -drive file=${IMAGE_PATH},format=qcow2 \
        -vnc :0 \
        -net nic -net user
else
    echo "❌ Unsupported Architecture: $ARCH"
    exit 1
fi
