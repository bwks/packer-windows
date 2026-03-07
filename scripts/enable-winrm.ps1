# Enable WinRM for Packer communicator
# This script is called from autounattend.xml FirstLogonCommands

# Log to a file for debugging
Start-Transcript -Path "C:\Windows\Temp\enable-winrm.log" -Append

# Wait for network adapter to be connected (VirtIO driver may take a moment)
Write-Host "Waiting for network..."
$retries = 0
while ($retries -lt 30) {
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if ($adapter) {
        Write-Host "Network adapter found: $($adapter.Name)"
        break
    }
    $retries++
    Start-Sleep -Seconds 2
}

# Set all network profiles to Private (required for WinRM)
# Use -ErrorAction SilentlyContinue since profile may not exist yet
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

# Stop WinRM if running, so we can configure it cleanly
Stop-Service -Name WinRM -Force -ErrorAction SilentlyContinue

# Configure WinRM via cmd - this is more reliable than Enable-PSRemoting on first boot
cmd /c 'winrm quickconfig -quiet'
cmd /c 'winrm set winrm/config @{MaxTimeoutms="1800000"}'
cmd /c 'winrm set winrm/config/service @{AllowUnencrypted="true"}'
cmd /c 'winrm set winrm/config/service/auth @{Basic="true"}'
cmd /c 'winrm set winrm/config/client/auth @{Basic="true"}'

# Ensure an HTTP listener exists
$listeners = cmd /c 'winrm enumerate winrm/config/listener' 2>&1
if ($listeners -notmatch "Transport = HTTP") {
    cmd /c 'winrm create winrm/config/listener?Address=*+Transport=HTTP'
}

# Set WinRM service to start automatically and start it
Set-Service -Name WinRM -StartupType Automatic
Restart-Service -Name WinRM

# Open firewall for WinRM HTTP
netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985

# Verify WinRM is listening
netstat -an | Select-String ":5985"

Write-Host "WinRM configured successfully."
Stop-Transcript
