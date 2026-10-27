packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "win2022" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  vm_name          = "${var.vm_name}.qcow2"
  output_directory = var.output_directory
  headless         = var.headless

  cpus      = var.vm_cpus
  memory    = var.vm_memory
  disk_size = var.disk_size

  accelerator    = "kvm"
  machine_type   = "pc"
  # A VirtIO disk, as on a Sherpa node, so the VirtIO storage driver is installed as a boot
  # driver; Windows does not boot from a VirtIO disk otherwise. The network card stays e1000:
  # installing the VirtIO guest tools reinstalls the VirtIO network driver, which would drop
  # Packer's WinRM connection mid-step and hang the build. The guest tools leave the VirtIO
  # network driver in the image, and Windows uses it on a Sherpa node's VirtIO network card.
  disk_interface = "virtio"
  net_device     = "e1000"
  format         = "qcow2"

  disk_compression = true

  vnc_bind_address = "0.0.0.0"

  # Floppy with Autounattend.xml
  floppy_files = [
    "answer_files/Autounattend.xml",
  ]

  # Secondary CD-ROM with scripts, the VirtIO storage driver for Windows setup, and the
  # VirtIO guest tools installer
  cd_files = [
    "scripts/enable-winrm.ps1",
    "drivers/viostor",
    "drivers/virtio-win-guest-tools.exe",
  ]
  cd_label = "cidata"

  qemuargs = [
    ["-cpu", "host"],
  ]

  # Boot command - press spacebar to trigger "Press any key to boot from CD"
  boot_wait    = "3s"
  boot_command = [" ", " ", " ", " "]

  # WinRM communicator
  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "60m"
  winrm_use_ssl  = false
  winrm_insecure = true

  # Sysprep handles shutdown
  shutdown_command = ""
  shutdown_timeout = "15m"
}

build {
  sources = ["source.qemu.win2022"]

  # Install VirtIO guest tools (drivers for disk, network, etc.)
  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    script            = "scripts/install-virtio.ps1"
  }

  # Install OpenSSH Server
  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    script            = "scripts/install-openssh.ps1"
  }

  # Install cloudbase-init
  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    script            = "scripts/install-cloudbase-init.ps1"
  }

  # Upload cloudbase-init configuration files
  provisioner "file" {
    source      = "config/cloudbase-init.conf"
    destination = "C:\\Program Files\\Cloudbase Solutions\\Cloudbase-Init\\conf\\cloudbase-init.conf"
  }

  provisioner "file" {
    source      = "config/cloudbase-init-unattend.conf"
    destination = "C:\\Program Files\\Cloudbase Solutions\\Cloudbase-Init\\conf\\cloudbase-init-unattend.conf"
  }

  # Cleanup temporary files and reduce image size
  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    script            = "scripts/cleanup.ps1"
  }

  # Run Sysprep - this will shut down the VM
  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    script            = "scripts/sysprep.ps1"
  }
}
