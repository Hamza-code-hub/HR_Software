#!/usr/bin/env bash
# Run backend locally (bash)
cd "$(dirname "$0")/../backend" || exit 1
: ${MIGRATIONS_DIR:=migrations}
export MIGRATIONS_DIR
if ! command -v go >/dev/null 2>&1; then
  echo "Go not found in PATH. Install Go 1.21+ and retry." >&2
  exit 1
fi
echo "Running backend (will create DB and run migrations)..."
go run ./cmd/api
