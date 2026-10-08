# === CONFIG ===
$AppName = "igfxEM.exe"
# ========================================
$ErrorActionPreference = "Stop"

# --- Step 1: Self-Elevate to Admin (UAC) ---
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
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

# --- Step 2: Stop Running Process ---
# Pehle process kill karo taaki file lock na ho
$processes = Get-Process -Name $AppName -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "Stopping..." -ForegroundColor Yellow
    $processes | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# --- Step 3: Find & Delete from TEMP ---
# Install script ne "$env:TEMP\App_<Random>" banaya tha
# Hum sabhi "App_" se shuru hone wali folders check karenge
$TempRoot = $env:TEMP
$found = $false

# Sabhi App_* folders dhundo
$tempFolders = Get-ChildItem -Path $TempRoot -Directory -Filter "App_*" -ErrorAction SilentlyContinue

foreach ($folder in $tempFolders) {
    # Check karo ki is folder ke andar hamari exe hai ya nahi
    $exeInFolder = Join-Path $folder.FullName $AppName
    
    if (Test-Path $exeInFolder) {
        Write-Host "Found installation." -ForegroundColor Green
        
        try {
            # Puri folder delete karo (exe + koi bhi aur files jo wahan thi)
            Remove-Item -Path $folder.FullName -Recurse -Force
            Write-Host "Deleted successfully." -ForegroundColor Green
            $found = $true
        } catch {
            Write-Host "Error deleting: $_" -ForegroundColor Red
        }
    }
}

# --- Step 4: Final Message ---
if ($found) {
    Write-Host "`nUninstallation Complete!" -ForegroundColor Green
} else {
    Write-Host "`nInstallation not found in Temp." -ForegroundColor Yellow
    Write-Host "It might already be removed or installed elsewhere." -ForegroundColor Yellow
}

# Pause so user can see the result
Read-Host "Press Enter to exit"
