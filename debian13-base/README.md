## Debian 13.02 (Trixie) - Base Image

This is a "Golden Image" for a server based on **Debian 13.02 (Trixie)**, created using **Packer** for **Proxmox VE**.

The image is a minimal, ready-to-use template that is fully automated and prepared for cloning.

### Key Features:

- A `root` user is created (with a password).
- SSH server is enabled.
- QEMU Guest Agent is enabled.
- Cloud-init is enabled.

### Installed Software:

- **mc** (Midnight Commander)
- **htop** (Interactive process viewer)

### VM Template Configuration:

- **Default VM ID:** 900
- **CPU:** 2 cores
- **Memory:** 2 GB
- **Disk:** 10 GB
- **Network:** 1 VirtIO adapter (bridge `vmbr0`)

### Preparation for Cloning:

After installation, the image is cleaned to ensure that each new VM created from this template is unique: the `machine-id` is reset, host SSH keys are removed, and logs and cloud-init data are cleared.
