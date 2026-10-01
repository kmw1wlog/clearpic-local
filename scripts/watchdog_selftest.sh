#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-48180}"
"$APP_DIR/scripts/serve_supervised.sh" "$PORT" &
PARENT_PID=$!
cleanup(){ kill "$PARENT_PID" 2>/dev/null || true; wait "$PARENT_PID" 2>/dev/null || true; }
trap cleanup EXIT
for _ in {1..20}; do [[ -f "$APP_DIR/.server-child.pid" ]] && break; sleep .25; done
FIRST_PID="$(cat "$APP_DIR/.server-child.pid")"
kill -9 "$FIRST_PID"
SECOND_PID=""
for _ in {1..40}; do
  sleep .25
  SECOND_PID="$(cat "$APP_DIR/.server-child.pid" 2>/dev/null || true)"
  if [[ -n "$SECOND_PID" && "$SECOND_PID" != "$FIRST_PID" ]] && kill -0 "$SECOND_PID" 2>/dev/null; then
    curl -fsS "http://127.0.0.1:$PORT/" 2>/dev/null | grep -q 'ClearPic Local' && break
  fi
done
[[ -n "$SECOND_PID" && "$SECOND_PID" != "$FIRST_PID" ]]
curl -fsS "http://127.0.0.1:$PORT/" | grep -q 'ClearPic Local'
printf 'PASS: child %s replaced by %s; app responds.\n' "$FIRST_PID" "$SECOND_PID"
