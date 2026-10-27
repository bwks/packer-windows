# Install the VirtIO guest tools (all VirtIO drivers and the QEMU guest agent) from the build
# CD, where the installer is placed from the local virtio-win.iso (see the README). The image
# boots from a VirtIO disk, so without the viostor driver it does not boot; the build stops
# here if the driver is not installed.

$ErrorActionPreference = "Stop"

$installer = Get-PSDrive -PSProvider FileSystem |
    ForEach-Object { Join-Path $_.Root "virtio-win-guest-tools.exe" } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1
if (-not $installer) {
    Write-Error "virtio-win-guest-tools.exe not found on any drive"
    exit 1
}

Write-Host "Installing VirtIO guest tools from $installer..."
$process = Start-Process -FilePath $installer -ArgumentList "/install", "/quiet", "/norestart" -Wait -NoNewWindow -PassThru
# 3010: installed, a restart is needed
if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010) {
    Write-Error "VirtIO guest tools installer failed with exit code $($process.ExitCode)"
    exit 1
}

$storageDriver = Get-WindowsDriver -Online | Where-Object { $_.OriginalFileName -like "*\viostor.inf" }
if (-not $storageDriver) {
    Write-Error "The VirtIO storage driver (viostor) is not installed; the image would not boot"
    exit 1
}

Write-Host "VirtIO guest tools installed (viostor $($storageDriver.Version))."
