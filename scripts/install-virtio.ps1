# Download and install VirtIO guest tools (includes all VirtIO drivers)

$virtioInstaller = "C:\Windows\Temp\virtio-win-guest-tools.exe"
$virtioUrl = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win-guest-tools.exe"

Write-Host "Downloading VirtIO guest tools..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $virtioUrl -OutFile $virtioInstaller -UseBasicParsing

Write-Host "Installing VirtIO guest tools..."
Start-Process -FilePath $virtioInstaller -ArgumentList "/install", "/quiet", "/norestart" -Wait -NoNewWindow

# Clean up installer
Remove-Item -Path $virtioInstaller -Force -ErrorAction SilentlyContinue

Write-Host "VirtIO guest tools installed."
