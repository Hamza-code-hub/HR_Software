#!/usr/bin/env bash
# Run frontend locally (bash, requires Flutter)
cd "$(dirname "$0")/../frontend" || exit 1
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter not found in PATH. Install Flutter SDK and retry." >&2
  exit 1
fi
flutter pub get
echo "Starting frontend (default: chrome)..."
flutter run -d chrome
