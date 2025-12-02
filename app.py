import os
import subprocess
import threading
import signal
import sys
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

# --- Configuration ---
# These paths match the Docker volume structure
UPLOAD_FOLDER = '/sandbox'
ISO_PATH = os.path.join(UPLOAD_FOLDER, 'input.iso')
QCOW_PATH = os.path.join(UPLOAD_FOLDER, 'windows.qcow2')

# Global state to report progress to the frontend
STATE = {
    "converting": False, 
    "ready": False
}

def convert_iso_and_exit():
    """
    Background worker that converts the ISO to QCOW2.
    Once finished, it kills the Flask server to let entrypoint.sh proceed.
    """
    global STATE
    STATE["converting"] = True
    print(f"[Loader] Starting conversion: {ISO_PATH} -> {QCOW_PATH}")

    # 1. Run qemu-img convert
    # Note: We use -f qcow2 and 20G size. Adjust size if needed.
    try:
        subprocess.run(
            ["qemu-img", "create", "-f", "qcow2", "-b", ISO_PATH, QCOW_PATH, "20G"],
            check=True
        )
        print("[Loader] Conversion successful.")
    except subprocess.CalledProcessError as e:
        print(f"[Loader] Error converting ISO: {e}")
        # In a real app, you might want to handle this error state in the UI
        sys.exit(1)

    # 2. Cleanup the ISO to save space
    if os.path.exists(ISO_PATH):
        os.remove(ISO_PATH)
        print("[Loader] Cleaned up temporary ISO.")

    STATE["converting"] = False
    STATE["ready"] = True
    
    print("[Loader] Shutting down Flask to handoff to QEMU...")
    
    # 3. Kill the current process (Flask)
    # This triggers the 'entrypoint.sh' to continue to the next step
    os.kill(os.getpid(), signal.SIGINT)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload():
    """Handle the file upload from the drag-and-drop UI"""
    if 'file' not in request.files:
        return jsonify({"success": False, "error": "No file part"}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({"success": False, "error": "No selected file"}), 400

    if file:
        print(f"[Loader] Receiving file: {file.filename}")
        file.save(ISO_PATH)
        
        # Start conversion in a background thread so the HTTP request completes
        threading.Thread(target=convert_iso_and_exit).start()
        
        return jsonify({"success": True})

@app.route('/status')
def status():
    """Frontend polls this to know when to refresh"""
    return jsonify(STATE)

if __name__ == '__main__':
    # Ensure upload directory exists
    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)

    # If the image already exists, we shouldn't be running this app at all.
    # But as a failsafe, if we are here, just run the server.
    print("[Loader] Starting Web Interface on port 8080...")
    app.run(host='0.0.0.0', port=8080)
