import os
import subprocess
import threading
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)
UPLOAD_FOLDER = '/sandbox'
ISO_PATH = os.path.join(UPLOAD_FOLDER, 'input.iso')
QCOW_PATH = os.path.join(UPLOAD_FOLDER, 'windows.qcow2')

# State flags
STATE = {"converting": False, "ready": False}

def start_qemu():
    """Starts the actual QEMU/NoVNC stack"""
    print("Starting QEMU...")
    # This calls your original startup logic
    subprocess.Popen(["/start-sandbox.sh"]) 
    STATE["ready"] = True

def convert_iso():
    """Converts uploaded ISO to QCOW2"""
    STATE["converting"] = True
    print("Converting ISO...")
    subprocess.run(["qemu-img", "create", "-f", "qcow2", "-b", ISO_PATH, QCOW_PATH, "20G"])
    STATE["converting"] = False
    
    # Clean up ISO to save space
    os.remove(ISO_PATH)
    
    # Boot the VM
    start_qemu()

@app.route('/')
def index():
    # If QEMU is already running, this page shouldn't be reachable 
    # (because NoVNC takes over port 8080), but as a fallback:
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload():
    file = request.files['file']
    if file:
        file.save(ISO_PATH)
        # Start conversion in background thread so request doesn't time out
        threading.Thread(target=convert_iso).start()
        return jsonify({"success": True})
    return jsonify({"success": False}), 400

@app.route('/status')
def status():
    return jsonify(STATE)

if __name__ == '__main__':
    # Check if disk already exists. If yes, skip straight to QEMU.
    if os.path.exists(QCOW_PATH):
        start_qemu()
        # Keep python alive or just wait? 
        # Better strategy: Exec into QEMU script if ready.
    else:
        app.run(host='0.0.0.0', port=8080)
