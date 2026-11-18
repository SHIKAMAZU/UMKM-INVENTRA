#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_CHANNEL="${FLUTTER_VERSION:-stable}"
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_CHANNEL" --depth 1 "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
fi

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release --dart-define=API_BASE_URL="${API_BASE_URL:?API_BASE_URL belum diatur di environment Netlify}"
