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
  if is_running; then
    echo "RUNNING (pid $(cat "$PIDFILE"))"
    return 0
  fi

  cd "$DIR" || return 1
  (
    trap 'rm -f "$PIDFILE"; exit 0' INT TERM EXIT
    while true; do
      "$PY" "$SCRIPT"
      sleep 10
    done
  ) >> "$LOG" 2>&1 &

  echo "$!" > "$PIDFILE"
  echo "STARTED (pid $!)"
  return 0
}

stop() {
  if is_running; then
    pid="$(cat "$PIDFILE" 2>/dev/null)"

    kill "$pid" 2>/dev/null || true
    pkill -TERM -P "$pid" 2>/dev/null || true

    i=0
    while kill -0 "$pid" 2>/dev/null; do
      i=$((i + 1))
      if [ "$i" -ge 12 ]; then
        break
      fi
      sleep 1
    done

    if kill -0 "$pid" 2>/dev/null; then
      pkill -KILL -P "$pid" 2>/dev/null || true
      kill -KILL "$pid" 2>/dev/null || true
      sleep 1
    fi

    if kill -0 "$pid" 2>/dev/null; then
      echo "FAILED TO STOP (pid $pid still running)" >&2
      return 1
    fi
  fi

  rm -f "$PIDFILE"
  echo "STOPPED"
  return 0
}

restart() {
  stop || return 1
  start
}

status() {
  if is_running; then
    echo "RUNNING (pid $(cat "$PIDFILE"))"
    return 0
  fi

  echo "STOPPED"
  return 1
}

show_tail() {
  touch "$LOG"
  tail -n 200 "$LOG"
}

case "$1" in
  start|"") start ;;
  stop) stop ;;
  restart) restart ;;
  status) status ;;
  tail) show_tail ;;
  *)
    echo "Usage: $0 {start|stop|restart|status|tail}"
    exit 2
    ;;
esac
