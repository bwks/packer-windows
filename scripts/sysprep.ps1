# Run Sysprep with cloudbase-init unattend
# This will generalize the image and shut down the VM

$cloudbaseInitDir = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init"
$unattendPath = Join-Path $cloudbaseInitDir "conf\Unattend.xml"

if (-not (Test-Path $unattendPath)) {
    Write-Error "cloudbase-init Unattend.xml not found at $unattendPath"
    exit 1
}

Write-Host "Running Sysprep..."
& "$env:SystemRoot\System32\Sysprep\sysprep.exe" `
    /generalize `
    /oobe `
    /shutdown `
    /unattend:"$unattendPath"

# Sysprep will shut down the VM - Packer will detect the shutdown and capture the image
