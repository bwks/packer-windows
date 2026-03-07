# Cleanup script - reduce image size

Write-Host "Cleaning up temporary files..."

# Clear user temp directory, preserving WinRM temp files used by Packer
Get-ChildItem -Path "C:\Users\Administrator\AppData\Local\Temp" -Exclude "winrmcp-*","packer-*" -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Clear Windows temp but preserve Packer's script files (packer-ps-env-vars-*, script-*)
Get-ChildItem -Path "C:\Windows\Temp" -Exclude "packer-*","script-*" -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Run DISM component cleanup
Write-Host "Running DISM component cleanup..."
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase

# Clear event logs
Write-Host "Clearing event logs..."
wevtutil el | ForEach-Object { wevtutil cl "$_" 2>$null }

Write-Host "Cleanup complete."
