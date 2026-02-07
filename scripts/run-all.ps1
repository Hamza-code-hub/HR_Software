#!/usr/bin/env pwsh
# Start backend in background and run frontend in foreground (PowerShell)
Set-Location -Path "$PSScriptRoot\.."

# Start backend in a background PowerShell process
$backendCmd = "Set-Location -Path '$PSScriptRoot\..\backend'; $env:MIGRATIONS_DIR='migrations'; go run ./cmd/api"
Start-Process -FilePath pwsh -ArgumentList '-NoProfile','-NoExit','-Command',$backendCmd

# Run frontend in current terminal
./scripts/run-frontend.ps1
