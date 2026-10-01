#!/usr/bin/env bash
set -u
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-4180}"
LOG_FILE="$APP_DIR/server.log"
PID_FILE="$APP_DIR/.server-child.pid"
STOP=0
trap 'STOP=1; [[ -f "$PID_FILE" ]] && kill "$(cat "$PID_FILE")" 2>/dev/null || true' INT TERM EXIT
cd "$APP_DIR"
while [[ "$STOP" -eq 0 ]]; do
  printf '[%s] start port=%s\n' "$(date -Is)" "$PORT" >> "$LOG_FILE"
  python3 -m http.server "$PORT" --bind 127.0.0.1 >> "$LOG_FILE" 2>&1 &
  CHILD_PID=$!
  printf '%s\n' "$CHILD_PID" > "$PID_FILE"
  wait "$CHILD_PID"
  STATUS=$?
  [[ "$STOP" -eq 1 ]] && break
  printf '[%s] child exit=%s; restart in 2s\n' "$(date -Is)" "$STATUS" >> "$LOG_FILE"
  sleep 2
done
rm -f "$PID_FILE"
