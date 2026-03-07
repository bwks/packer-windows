# Packer Windows Server 2022

Build a Windows Server 2022 Datacenter (Desktop Experience) qcow2 image with [cloudbase-init](https://cloudbase.it/cloudbase-init/) and OpenSSH Server, targeting KVM/libvirt deployment.

## Features

- QEMU/KVM builder with VirtIO drivers (disk + network)
- cloudbase-init for cloud metadata (NoCloud + HTTP)
- OpenSSH Server with PowerShell as default shell
- Sysprep generalized image ready for cloning/deployment
- BIOS boot, compressed qcow2 output

## Prerequisites

### Host packages

```bash
# Ubuntu/Debian
sudo apt install qemu-kvm qemu-utils xorriso

# Fedora/RHEL
sudo dnf install qemu-kvm qemu-img xorriso
```

[Packer](https://developer.hashicorp.com/packer/install) >= 1.9.0 must be installed. Verify `/dev/kvm` is accessible.

> **Note on WinRM:** Packer has a built-in WinRM communicator (written in Go). No pywinrm or other Python packages are needed on the Linux host.

### ISO downloads

1. **Windows Server 2022 ISO** (~5.1 GB)
   Download from [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022)

2. **VirtIO Windows drivers ISO** (~600 MB)
   Download from [Fedora VirtIO-Win](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)

### Extract VirtIO drivers

The VirtIO drivers must be extracted from the ISO into the `drivers/` directory. Only the viostor (disk) and NetKVM (network) drivers for 2k22/amd64 are needed:

```bash
xorriso -osirrox on -indev virtio-win.iso \
  -extract /viostor/2k22/amd64 drivers/viostor \
  -extract /NetKVM/2k22/amd64 drivers/NetKVM
```

## Usage

### 1. Initialize Packer plugins

```bash
packer init .
```

### 2. Configure variables

```bash
cp windows-server-2022.auto.pkrvars.hcl.example windows-server-2022.auto.pkrvars.hcl
```

Edit `windows-server-2022.auto.pkrvars.hcl` with your ISO path and checksum:

```hcl
iso_url        = "./server2022.iso"
iso_checksum   = "sha256:abc123..."
winrm_password = "packer"
```

Generate the ISO checksum with:

```bash
sha256sum server2022.iso
```

### 3. Validate

```bash
packer validate .
```

### 4. Build

```bash
packer build .
```

The build takes roughly 30-60 minutes. The output qcow2 image will be in `output-win2022/`.

To monitor the build via VNC (useful on headless servers), watch the Packer output for a line like `Found available VNC port: 5982` and connect with a VNC client.

### 5. Test the image

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -drive file=output-win2022/win2022-cloudbase.qcow2,format=qcow2 \
  -nic user,hostfwd=tcp::2222-:22
```

Then SSH in with: `ssh -p 2222 Admin@localhost`

## Configuration

### Variables

| Variable | Default | Description |
|---|---|---|
| `iso_url` | (required) | Path or URL to Windows Server 2022 ISO |
| `iso_checksum` | (required) | ISO checksum (`sha256:...`) |
| `winrm_password` | (required) | Administrator password for build |
| `winrm_username` | `Administrator` | WinRM username |
| `vm_cpus` | `4` | Number of vCPUs |
| `vm_memory` | `8192` | Memory in MB |
| `disk_size` | `61440M` | Disk size |
| `headless` | `true` | Run QEMU without display |
| `output_directory` | `output-win2022` | Output directory |
| `vm_name` | `win2022-cloudbase` | Output filename (without .qcow2) |
| `virtio_iso_path` | `""` | Path to VirtIO drivers ISO |

### Image selection

The autounattend.xml selects `Windows Server 2022 Datacenter (Desktop Experience)` by default. To use a different edition, edit `answer_files/autounattend.xml` and change the `IMAGE/NAME` value. Common options:

- `Windows Server 2022 Standard Evaluation` (Server Core, eval)
- `Windows Server 2022 Standard Evaluation (Desktop Experience)` (GUI, eval)
- `Windows Server 2022 Datacenter Evaluation` (Server Core, eval)
- `Windows Server 2022 Datacenter Evaluation (Desktop Experience)` (GUI, eval)
- `Windows Server 2022 Datacenter (Desktop Experience)` (LTSC, non-eval)

### cloudbase-init

The image ships with cloudbase-init configured for:
- **NoCloud** (`cidata` label) and **HTTP** metadata services
- User creation, SSH public keys, hostname, network config
- Volume extension, userdata execution, WinRM listener setup

Config files are in `config/` and get placed in `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\`.

## Project Structure

```
├── windows-server-2022.pkr.hcl           # Main Packer template
├── variables.pkr.hcl                      # Variable definitions
├── windows-server-2022.auto.pkrvars.hcl.example
├── answer_files/
│   └── autounattend.xml                   # Unattended Windows install
├── drivers/                               # Extracted from virtio-win.iso (git-ignored)
│   ├── viostor/                           # VirtIO block driver
│   └── NetKVM/                            # VirtIO network driver
├── scripts/
│   ├── enable-winrm.ps1                   # WinRM for Packer communicator
│   ├── install-virtio.ps1                 # VirtIO guest tools
│   ├── install-openssh.ps1                # OpenSSH Server
│   ├── install-cloudbase-init.ps1         # cloudbase-init
│   ├── cleanup.ps1                        # Image size reduction
│   └── sysprep.ps1                        # Generalize + shutdown
└── config/
    ├── cloudbase-init.conf                # Main config
    └── cloudbase-init-unattend.conf       # Unattend-phase config
```

## License

MIT
