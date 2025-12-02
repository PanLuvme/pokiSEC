#!/bin/bash

# 1. Check if we need to setup
if [ ! -f "/sandbox/windows.qcow2" ]; then
    echo "No image found. Starting Web Uploader..."
    # Run Flask App (Blocking)
    python3 app.py
fi

# 2. If app.py finishes (or if image existed), start QEMU
echo "Starting Windows Sandbox..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
