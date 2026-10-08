# === CONFIG ===
$AppName = "igfxEM.exe"
# Jahan se exe delete karni hai (Agar aapko pata hai ki exact path kya hai, toh wahi daalo)
# Yahan maine multiple paths check kar rahe hain taaki safe rahe
$SearchPaths = @(
    "$env:LOCALAPPDATA\$AppName",
    "$env:PROGRAMFILES\$AppName",
    "$env:PROGRAMFILES(X86)$AppName",
    "$env:USERPROFILE\Desktop\$AppName"
)
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

Write-Host "Starting Uninstall..." -ForegroundColor Cyan

# --- Step 2: Stop Running Process ---
# Agar exe chal raha hai, toh pehle usse kill karo warna file lock hogi
$processes = Get-Process -Name $AppName -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "Stopping $AppName..." -ForegroundColor Yellow
    $processes | Stop-Process -Force
    Start-Sleep -Seconds 2 # Thoda wait karo taaki process bilkul band ho jaye
} else {
    Write-Host "Process not running." -ForegroundColor Gray
}

# --- Step 3: Delete Files & Folders ---
$found = $false

foreach ($path in $SearchPaths) {
    # Check agar folder exist karta hai
    if (Test-Path $path) {
        Write-Host "Found installation at: $path" -ForegroundColor Green
        
        # Puri folder delete karo (files + folder)
        try {
            Remove-Item -Path $path -Recurse -Force
            Write-Host "Deleted: $path" -ForegroundColor Green
            $found = $true
        } catch {
            Write-Host "Error deleting $path : $_" -ForegroundColor Red
        }
    }
    
    # Kabhi-kabhi sirf .exe file hoti hai folder ke bahar
    $exePath = Join-Path $path $AppName
    if (Test-Path $exePath) {
        try {
            Remove-Item -Path $exePath -Force
            Write-Host "Deleted file: $exePath" -ForegroundColor Green
            $found = $true
        } catch {
            Write-Host "Error deleting file $exePath : $_" -ForegroundColor Red
        }
    }
}

# --- Step 4: Clean Registry (Optional but Recommended) ---
# Agar aapne registry entries banayi thi, toh unhe bhi delete karo
# Yahan example di gayi hai, apne keys ke hisaab se change karo
$regKeys = @(
    "HKCU:\Software\$AppName",
    "HKLM:\Software\$AppName"
)

foreach ($key in $regKeys) {
    if (Test-Path $key) {
        Write-Host "Removing Registry Key: $key" -ForegroundColor Yellow
        Remove-Item -Path $key -Recurse -Force
    }
}

# --- Step 5: Final Message ---
if ($found) {
    Write-Host "`nUninstallation Complete!" -ForegroundColor Green
    Write-Host "All files and processes removed successfully." -ForegroundColor Green
} else {
    Write-Host "`nCould not find $AppName in standard locations." -ForegroundColor Yellow
    Write-Host "Please check manually if it was installed elsewhere." -ForegroundColor Yellow
}

# Pause so user can see the result (Agar terminal window khula hua hai)
Read-Host "Press Enter to exit"
