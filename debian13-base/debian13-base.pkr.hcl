// file: packer/debian13-base/debian13-base.pkr.hcl

// Proxmox plugin
packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = "~> 1"
    }
  }
}

// Variables: their definitions are in secrets.auto.pkvars.hcl
variable "proxmox_host" {
  type    = string
}
variable "proxmox_token_id" {
  type    = string
  sensitive = true
}
variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}
variable "root_ssh_password" {
  type      = string
  sensitive = true
}

// Source block - defines how to create the base VM from an ISO
source "proxmox-iso" "debian13" {
  // --- Connection settings ---
  proxmox_url              = "https://${var.proxmox_host}:8006/api2/json"
  username                 = var.proxmox_token_id
  token                    = var.proxmox_token_secret
  insecure_skip_tls_verify = true

  // --- Proxmox settings ---
  node    = "proxmox"            
  vm_id   = "900"              
  vm_name = "debian13-base"     
  
  // --- ISO and installation settings ---
  boot_iso {
  type             = "scsi"
  iso_file         = "local:iso/debian-13.2.0-amd64-netinst.iso"
  iso_storage_pool = "local"
  unmount          = true
  }
    
  // --- VM settings ---
  memory = 1024
  cores  = 1
  sockets = 1
  machine = "q35"
  bios    = "ovmf"

  scsi_controller = "virtio-scsi-pci"
  
  
  efi_config {
    efi_storage_pool  = "local-lvm"
    pre_enrolled_keys = true
  }

  disks {
    type         = "scsi"
    disk_size    = "5G"
    storage_pool = "local-lvm"
    format       = "raw"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  // Enable Cloud-Init
  cloud_init = true
  cloud_init_storage_pool = "local-lvm"

  // Enable QEMU Guest Agent
  qemu_agent = true

  // --- Automated installation via preseed.cfg ---
  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/preseed.pkrtpl.hcl", {
      root_password = var.root_ssh_password
    })
  }

  boot_wait = "8s"
  boot_command = [
  "<wait><wait>",
  "e",
  "<wait>",
  "<down><down><down><end>",
  " auto ",
  "priority=critical ",
  "DEBCONF_DEBUG=5 ",
  "interface=auto ",
  "netcfg/disable_dhcp=false ",
  "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
  "debian-installer/locale=en_US.UTF-8 ",
  "console-keymaps-at/keymap=us ",
  "keyboard-configuration/xkb-keymap=us ",
  "<f10>"
 ]


  // --- SSH settings ---
  ssh_username           = "root"
  ssh_password           = var.root_ssh_password
  ssh_timeout            = "15m"
  ssh_handshake_attempts = 100
 
  // Convert to template after creation
  template_name        = "debian13-base"
  template_description = "Debian 13 base - GoldenImage"
}

// Build block - OS configuration after installation
build {
  name    = "debian13-base"
  sources = ["source.proxmox-iso.debian13"]

  // 1. Update the system and install packages
  provisioner "shell" {
    inline = [
	  "set -x",
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      // install packages
      "apt-get install -y mc htop",
      "apt-get autoremove -y",
      "apt-get clean"
    ]
  }

  // 2. Cleanup for the golden image
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; /bin/bash {{ .Path }}" 
    inline = [
      "set -x",
      // Clean Cloud-Init (important for OpenTofu/Terraform)
      "cloud-init clean --log --seed",
      "rm -rf /var/lib/cloud/instances/*",

      // Clean SSH host keys (so each VM gets its own)
      "rm -f /etc/ssh/ssh_host_*",

      // Reset Machine ID (to avoid network IP conflicts)
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id", # on some systems this is a symlink
      "ln -s /etc/machine-id /var/lib/dbus/machine-id",

      // Clean logs and history
      "find /var/log -type f -exec truncate --size 0 {} \\;",
      "history -c",
      "rm -f /root/.bash_history",
      
      // Flush buffers to disk
      "sync"
    ]
  }
}