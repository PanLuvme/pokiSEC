import os
import signal
import time
import threading
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

UPLOAD_FOLDER = '/sandbox'
FINAL_PATH = os.path.join(UPLOAD_FOLDER, 'windows.qcow2')

def shutdown_server():
    """Waits a moment for the response to send, then kills Flask."""
    time.sleep(1)
    print("[Loader] File saved. Shutting down Flask to handoff to QEMU...")
    os.kill(os.getpid(), signal.SIGINT)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload():
    """Handle the .qcow2 file upload"""
    if 'file' not in request.files:
        return jsonify({"success": False, "error": "No file part"}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({"success": False, "error": "No selected file"}), 400

    if file:
        print(f"[Loader] Receiving QCOW2 file: {file.filename}")
        file.save(FINAL_PATH)
        
        # Trigger shutdown in background
        threading.Thread(target=shutdown_server).start()
        
        return jsonify({"success": True})

if __name__ == '__main__':
    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)
    
    print("[Loader] Ready for QCOW2 Upload on port 8080...")
    app.run(host='0.0.0.0', port=8080)
