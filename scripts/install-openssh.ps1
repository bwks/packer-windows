# Install OpenSSH Server on Windows Server 2025

Write-Host "Installing OpenSSH Server..."
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Set sshd service to start automatically
Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd

# Open firewall rule for SSH
New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
    -DisplayName "OpenSSH Server (sshd)" `
    -Enabled True `
    -Direction Inbound `
    -Protocol TCP `
    -Action Allow `
    -LocalPort 22 `
    -ErrorAction SilentlyContinue

# Set default shell to PowerShell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" `
    -Name DefaultShell `
    -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -PropertyType String `
    -Force

Write-Host "OpenSSH Server installed and configured."
