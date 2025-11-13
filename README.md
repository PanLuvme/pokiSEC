![logo](https://i.postimg.cc/wBgLFnjq/pokisecreadme.png)

a happy little sandbox for not-so-happy files

> It uses QEMU and Docker to build a completely isolated, disposable Windows VM, streaming it right to your browser tab. Safely detonate malware or test suspicious apps, then just close the tab—poof! The entire environment is wiped clean.

## ⚠️ Requirements

* Docker
* A Linux host with KVM support (for performance)
* A Windows `.qcow2` disk image

## 🚀 How to Use

1.  **Get Your VM Image:**
    * Download a Windows evaluation VM from the [Microsoft Developer website](https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/).
    * Convert it to `.qcow2` format.
    * Rename it to `windows.qcow2` and place it in this project's directory.

2.  **Build the Docker Image:**
    ```sh
    docker build -t my-sandbox .
    ```

3.  **Run the Sandbox:**
    ```sh
    docker run --rm -it \
      -p 8080:8080 \
      --device=/dev/kvm \
      -v ./windows.qcow2:/sandbox/windows.qcow2 \
      my-sandbox
    ```
    * `--rm`: Automatically deletes the container when you stop it.
    * `-p 8080:8080`: Maps the web UI to your localhost port 8080.
    * `--device=/dev/kvm`: Gives the container access to hardware virtualization (massive speed boost).
    * `-v`: This is the magic. It mounts your local `windows.qcow2` file into the container.

4.  **Access Your Sandbox:**
    Open your browser and go to:
    **`http://localhost:8080`**
