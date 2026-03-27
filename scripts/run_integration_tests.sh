#!/usr/bin/env bash
#
# run_integration_tests.sh
#
# Runs NeighbourGo integration tests on an iOS Simulator with Firebase Emulators.
#
# Prerequisites:
#   - Firebase CLI installed (npm install -g firebase-tools)
#   - Xcode + iOS Simulator available
#   - Flutter SDK on PATH
#
# Usage:
#   ./scripts/run_integration_tests.sh              # auto-detect booted simulator
#   ./scripts/run_integration_tests.sh <device_id>  # use a specific device
#

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

DEVICE_ID="${1:-}"
EMULATOR_PID=""

# --- Cleanup on exit ---
cleanup() {
  echo ""
  echo "==> Cleaning up..."
  if [[ -n "$EMULATOR_PID" ]] && kill -0 "$EMULATOR_PID" 2>/dev/null; then
    echo "    Stopping Firebase Emulators (PID $EMULATOR_PID)..."
    kill "$EMULATOR_PID" 2>/dev/null || true
    wait "$EMULATOR_PID" 2>/dev/null || true
  fi
  echo "    Done."
}
trap cleanup EXIT

# --- Start Firebase Emulators ---
echo "==> Starting Firebase Emulators..."
firebase emulators:start --only auth,firestore,storage,functions &
EMULATOR_PID=$!

# Wait for emulators to be ready (check Firestore port 8080)
echo "==> Waiting for emulators to be ready..."
MAX_WAIT=30
WAITED=0
while ! curl -s http://localhost:4000 > /dev/null 2>&1; do
  sleep 1
  WAITED=$((WAITED + 1))
  if [[ $WAITED -ge $MAX_WAIT ]]; then
    echo "ERROR: Firebase Emulators did not start within ${MAX_WAIT}s"
    exit 1
  fi
done
echo "    Emulators ready (waited ${WAITED}s)."

# --- Resolve iOS Simulator device ---
if [[ -z "$DEVICE_ID" ]]; then
  # Try to find a booted simulator
  DEVICE_ID=$(xcrun simctl list devices booted -j 2>/dev/null \
    | grep '"udid"' | head -1 | sed 's/.*: "\(.*\)".*/\1/' || true)
  if [[ -z "$DEVICE_ID" ]]; then
    echo "==> No booted iOS Simulator found. Booting default iPhone..."
    DEVICE_ID=$(xcrun simctl list devices available -j 2>/dev/null \
      | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' in runtime:
        for d in devices:
            if d.get('isAvailable') and 'iPhone' in d.get('name', ''):
                print(d['udid'])
                sys.exit(0)
" 2>/dev/null || true)
    if [[ -z "$DEVICE_ID" ]]; then
      echo "ERROR: No available iPhone simulator found."
      exit 1
    fi
    xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
    echo "    Booted simulator: $DEVICE_ID"
  else
    echo "==> Using booted simulator: $DEVICE_ID"
  fi
fi

# --- Run integration tests ---
echo "==> Running integration tests on device $DEVICE_ID..."
echo ""
flutter test integration_test/ -d "$DEVICE_ID"
EXIT_CODE=$?

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "==> All integration tests PASSED."
else
  echo "==> Some integration tests FAILED (exit code $EXIT_CODE)."
fi

exit $EXIT_CODE
