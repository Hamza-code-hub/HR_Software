#!/usr/bin/env pwsh
# Run backend locally (PowerShell)
Set-Location -Path "$PSScriptRoot\..\backend"
$env:MIGRATIONS_DIR = "migrations"
if ($null -eq $env:DATABASE_URL) {
    $env:DATABASE_URL = "postgres://postgres:123456@localhost:5432/hr_saas?sslmode=disable"
}
if ($null -eq $env:JWT_SECRET) {
    $env:JWT_SECRET = "dev-secret-123"
}
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "Go not found in PATH. Install Go 1.21+ and retry." -ForegroundColor Red
    exit 1
}
Write-Host "Running backend (will create DB and run migrations)..."
go run ./cmd/api
