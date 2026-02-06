#!/usr/bin/env pwsh
# Run backend locally (PowerShell)
Set-Location -Path "$PSScriptRoot\..\backend"
$env:MIGRATIONS_DIR = "migrations"
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "Go not found in PATH. Install Go 1.21+ and retry." -ForegroundColor Red
    exit 1
}
Write-Host "Running backend (will create DB and run migrations)..."
go run ./cmd/api
