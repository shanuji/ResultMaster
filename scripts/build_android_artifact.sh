#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter is required to build Android artifacts." >&2
  echo "Install Flutter, ensure it is on PATH, then rerun this script." >&2
  exit 127
fi

flutter pub get

if [[ -n "${RESULTMASTER_KEYSTORE:-}" && -n "${RESULTMASTER_KEYSTORE_PASSWORD:-}" && -n "${RESULTMASTER_KEY_ALIAS:-}" && -n "${RESULTMASTER_KEY_PASSWORD:-}" ]]; then
  echo "Building signed release APK with RESULTMASTER_* signing environment."
  flutter build apk --release
  echo "Release APK: $ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
else
  echo "Signing environment is incomplete; building debug APK instead." >&2
  flutter build apk --debug
  echo "Debug APK: $ROOT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
fi
