# Debian 13 (Trixie) - Base Image (UEFI + LVM)

This is a "Golden Image" template for **Debian 13 (Trixie)**, built with **Packer** for **Proxmox VE**. 
It serves as a minimalist, highly flexible foundation for various projects, including LFS builders, web servers, or development environments.

## Key Features

- **Boot:** UEFI (`OVMF`) support with **GPT** partition table.
- **Storage Management:** **LVM** (Logical Volume Manager) enabled by default for easy disk scaling.
- **Remote Access:** `root` login enabled via SSH (supports both password and keys).

## Disk Partitioning (LVM)

The image uses a structured LVM layout within a 5GB disk:
- `/boot/efi`: 512MB (vfat) — EFI System Partition.
- `/boot`: 512MB (ext4) — Linux Kernel & Initrd.
- **Volume Group (`vg_system`):**
    - `root` (LV): ~4GB (ext4) — Root filesystem.

## Networking Stack

The image has been migrated from the legacy `ifupdown` to **systemd-networkd** for improved performance and cloud compatibility.

- **Network Manager:** `systemd-networkd` (enabled).
- **DNS:** `systemd-resolved` (stub listener configured).
- **Cloud-Init:** Explicitly configured to use the `networkd` renderer.
- **Removed:** `ifupdown`, `resolvconf`.


## Installed Software

- **Core:** `openssh-server`, `cloud-init`, `qemu-guest-agent`, `locales`.
- **Utilities:** `mc` (Midnight Commander), `htop`.

## Build Specifications (Template Resources)

These resources are used for the **base template**. When cloning via OpenTofu/Terraform, these can be scaled up (e.g., to 12GB RAM / 5+ Cores for LFS).
- **CPU:** 1 Core
- **Memory:** 1 Gb
- **Disk:** 5 GB (Scsi/VirtIO)
- **Machine Type:** `q35`
- **BIOS:** `OVMF` (UEFI)

## Image Cleanup (Golden Image Prep)

To ensure each cloned VM is unique, the following cleanup steps are performed during the build:
- **Machine ID:** Reset (`/etc/machine-id` truncated).
- **SSH Host Keys:** Removed (regenerated automatically on first boot).
- **Cloud-Init:** Logs and instance data purged (`cloud-init clean`).
- **Logs:** System logs truncated to save space.
- **History:** Root bash history cleared.

## Usage

1. Build the image using Packer: `packer build .`
2. The resulting template (ID 900) will appear in Proxmox.
3. Use **OpenTofu/Terraform** to clone this template and expand the LVM partitions as needed.