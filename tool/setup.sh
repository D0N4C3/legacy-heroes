#!/usr/bin/env bash
# Legacy Heroes — one-shot project setup.
# Generates native platform folders with the correct package name, fetches
# dependencies, and optionally configures Firebase.
set -euo pipefail

ORG="com.qewiygames"   # -> applicationId / bundle id: com.qewiygames.legacyheroes

echo "==> Generating platform folders (org: $ORG)…"
flutter create --org "$ORG" --platforms=android,ios,web .

echo "==> Fetching dependencies…"
flutter pub get

if command -v flutterfire >/dev/null 2>&1; then
  read -r -p "==> Configure Firebase now with flutterfire? [y/N] " yn
  if [[ "${yn:-N}" =~ ^[Yy]$ ]]; then
    flutterfire configure
    echo "    Remember to switch FirebaseService.init() to use DefaultFirebaseOptions"
    echo "    (see README → Firebase setup)."
  fi
else
  echo "==> flutterfire CLI not found — skipping Firebase config."
  echo "    Install with: dart pub global activate flutterfire_cli"
fi

echo "==> Done. Run the game with:  flutter run"
