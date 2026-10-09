$ErrorActionPreference = "Stop"

$AppName = "igfxEM.exe"

Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($AppName)) -ErrorAction SilentlyContinue |
    Stop-Process -Force

Get-ChildItem "$env:TEMP" -Directory -Filter "App_*" -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
