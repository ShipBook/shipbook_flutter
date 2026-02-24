#!/bin/bash
# Load .env and run flutter with --dart-define flags
set -a
source .env
set +a

flutter run \
  --dart-define=SHIPBOOK_URL="$SHIPBOOK_URL" \
  --dart-define=SHIPBOOK_APP_ID="$SHIPBOOK_APP_ID" \
  --dart-define=SHIPBOOK_APP_KEY="$SHIPBOOK_APP_KEY" \
  "$@"
