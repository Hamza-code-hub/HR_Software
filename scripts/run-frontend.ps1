#!/usr/bin/env pwsh
# Run frontend locally (PowerShell, requires Flutter)
Set-Location -Path "$PSScriptRoot\..\frontend"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter not found in PATH. Install Flutter SDK and retry." -ForegroundColor Red
    exit 1
}
Write-Host "Running flutter pub get..."
flutter pub get
Write-Host "Starting frontend (default: chrome)..."
flutter run -d chrome
