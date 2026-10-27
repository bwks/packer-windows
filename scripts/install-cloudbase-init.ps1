# Download and install cloudbase-init

$cloudbaseInitMsi = "C:\Windows\Temp\CloudbaseInitSetup.msi"
$cloudbaseInitUrl = "https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi"

Write-Host "Downloading cloudbase-init..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $cloudbaseInitUrl -OutFile $cloudbaseInitMsi -UseBasicParsing

Write-Host "Installing cloudbase-init..."
$installArgs = @(
    "/i", $cloudbaseInitMsi,
    "/qn",
    "/l*v", "C:\Windows\Temp\cloudbase-init-install.log",
    "USERNAME=Admin",
    "LOGGINGSERIALPORTNAME=COM1",
    # Run as LocalSystem, not a "cloudbase-init" user. As that user, the first run resets
    # the user's password, then can fail to load its profile so early in boot ("The device
    # is not ready") before the service is given the new password; after the reboot the
    # service cannot log on, and the user data is never applied.
    "RUN_SERVICE_AS_LOCAL_SYSTEM=1"
)
Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -NoNewWindow

$serviceAccount = (Get-CimInstance Win32_Service -Filter "Name='cloudbase-init'").StartName
if ($serviceAccount -ne "LocalSystem") {
    Write-Error "cloudbase-init runs as '$serviceAccount', expected LocalSystem"
    exit 1
}

# Stop the service - it should not run until after sysprep
Stop-Service -Name cloudbase-init -Force -ErrorAction SilentlyContinue

# Set service to automatic start (will run after sysprep on first boot)
Set-Service -Name cloudbase-init -StartupType Automatic

# Clean up installer
Remove-Item -Path $cloudbaseInitMsi -Force -ErrorAction SilentlyContinue

Write-Host "cloudbase-init installed."
