#!/usr/bin/env sh
set -eu

APP_FILE="$PWD/app.env"
DEFAULT_ENV_FILE="$PWD/default.env"
TEMP_FILE="/tmp/wg-$$.tmp"

. "$DEFAULT_ENV_FILE"

PASSWORD_HASH="$(docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$APP_ADMIN_PASS" | sed -n "s/^PASSWORD_HASH='\(.*\)'$/\1/p")"

if [ -z "$PASSWORD_HASH" ]; then
  echo "Failed to generate APP_ADMIN_HASH" >&2
  exit 1
fi

if grep -q '^export APP_ADMIN_HASH=' "$DEFAULT_ENV_FILE"; then
  sed "/^export APP_ADMIN_PASS=/a\\
export APP_ADMIN_HASH=\"$PASSWORD_HASH\"
" "$DEFAULT_ENV_FILE" > "$TEMP_FILE"
else
  sed "/^export APP_ADMIN_PASS=/a\export APP_ADMIN_HASH=\"$PASSWORD_HASH\"" "$DEFAULT_ENV_FILE" > "$TEMP_FILE"
fi

if ! grep -q '^export APP_ADMIN_PASS=' "$TEMP_FILE"; then
  echo "Validation failed: APP_ADMIN_PASS missing" >&2
  rm -f "$TEMP_FILE"
  exit 1
fi

if ! grep -q '^export APP_ADMIN_HASH=' "$TEMP_FILE"; then
  echo "Validation failed: APP_ADMIN_HASH missing" >&2
  rm -f "$TEMP_FILE"
  exit 1
fi

if ! grep -q "$PASSWORD_HASH" "$TEMP_FILE"; then
  echo "Validation failed: hash mismatch" >&2
  rm -f "$TEMP_FILE"
  exit 1
fi

if [ -s "$TEMP_FILE" ]; then
  mv "$TEMP_FILE" "$DEFAULT_ENV_FILE"
else
  echo "Validation failed: temp file is empty" >&2
  rm -f "$TEMP_FILE"
  exit 1
fi
exit
