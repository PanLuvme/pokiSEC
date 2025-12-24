import os
import signal
import sys
from flask import Flask, render_template, request, jsonify
from werkzeug.utils import secure_filename

app = Flask(__name__)

UPLOAD_FOLDER = '/data'
PAYLOAD_STAGING = '/payloads_staging'
SIGNAL_FILE = '/tmp/boot_signal'

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(PAYLOAD_STAGING, exist_ok=True)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload_os', methods=['POST'])
def upload_os():
    file = request.files['file']
    if file:
        filename = "windows.qcow2"
        save_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(save_path)
        return jsonify({"status": "success", "message": "OS Image Uploaded"})
    return jsonify({"status": "error"}), 400

@app.route('/upload_payload', methods=['POST'])
def upload_payload():
    files = request.files.getlist('files[]')
    if not files:
        return jsonify({"status": "error", "message": "No files received"}), 400
    
    saved_files = []
    for file in files:
        if file.filename == '':
            continue
        filename = secure_filename(file.filename)
        file.save(os.path.join(PAYLOAD_STAGING, filename))
        saved_files.append(filename)
        
    return jsonify({"status": "success", "count": len(saved_files)})

@app.route('/launch', methods=['POST'])
def launch():
    with open(SIGNAL_FILE, 'w') as f:
        f.write("BOOT_READY")
    
    os.kill(os.getpid(), signal.SIGTERM)
    return "Booting..."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
