#!/bin/sh
# USVWatch Loop Wrapper (10s)
# Copyright (c) 2026 Roman Glos

DIR="$(cd "$(dirname "$0")" && pwd)"
PY="/usr/bin/python3"
SCRIPT="$DIR/usvwatch.py"
PIDFILE="$DIR/usvwatch.loop.pid"
LOG="$DIR/usvwatch-loop.log"

is_running() {
  [ -f "$PIDFILE" ] || return 1
  pid="$(cat "$PIDFILE" 2>/dev/null)" || return 1
  [ -n "$pid" ] || return 1
  kill -0 "$pid" 2>/dev/null
}

start() {
  if is_running; then exit 0; fi
  cd "$DIR" || exit 1
  (
    trap 'rm -f "$PIDFILE"; exit 0' INT TERM EXIT
    while true; do
      "$PY" "$SCRIPT"
      sleep 10
    done
  ) >> "$LOG" 2>&1 &
  echo $! > "$PIDFILE"
  exit 0
}

stop() {
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null || true
  fi
  exit 0
}

status() {
  if is_running; then
    echo "RUNNING (pid $(cat "$PIDFILE"))"
  else
    echo "STOPPED"
  fi
}

case "$1" in
  start|"") start ;;
  stop) stop ;;
  restart) stop; sleep 1; start ;;
  status) status ;;
  tail) tail -n 200 "$LOG" ;;
  *) echo "Usage: $0 {start|stop|restart|status|tail}"; exit 2 ;;
esac
