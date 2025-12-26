#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-}"
OUT_PATH="${2:-}"

if [[ -z "${APP_PATH}" ]]; then
  echo "Usage: $0 /path/to/Tock.app [output.dmg]" >&2
  exit 1
fi

if [[ ! -d "${APP_PATH}" ]]; then
  echo "App not found: ${APP_PATH}" >&2
  exit 1
fi

if [[ -z "${OUT_PATH}" ]]; then
  mkdir -p dist
  OUT_PATH="dist/Tock.dmg"
fi

mkdir -p "$(dirname "${OUT_PATH}")"

VOLUME_NAME="Tock"
STAGING_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

cp -R "${APP_PATH}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

if [[ -f "${OUT_PATH}" ]]; then
  rm -f "${OUT_PATH}"
fi

touch "build/.metadata_never_index" 2>/dev/null || true
touch "build/Build/.metadata_never_index" 2>/dev/null || true

hdiutil create \
  -volname "${VOLUME_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${OUT_PATH}"

echo "Created ${OUT_PATH}"
