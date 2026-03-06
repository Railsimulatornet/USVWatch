#!/bin/sh
# USVWatch Loop Wrapper (10s)
# Copyright (c) 2026 Roman Glos

DIR="$(cd "$(dirname "$0")" && pwd)"
PY="${PYTHON:-/usr/bin/python3}"
SCRIPT="$DIR/usvwatch.py"
PIDFILE="$DIR/usvwatch.loop.pid"
LOG="$DIR/usvwatch-loop.log"
INTERVAL="${USVWATCH_LOOP_INTERVAL:-10}"
STOP_TIMEOUT="${USVWATCH_STOP_TIMEOUT:-15}"

cleanup_stale_pidfile() {
  [ -f "$PIDFILE" ] || return 0
  pid="$(cat "$PIDFILE" 2>/dev/null)"
  case "$pid" in
    ''|*[!0-9]*)
      rm -f "$PIDFILE"
      return 0
      ;;
  esac
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PIDFILE"
  fi
}

is_running() {
  cleanup_stale_pidfile
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

  [ -f "$SCRIPT" ] || {
    echo "ERROR: Script not found: $SCRIPT" >&2
    return 1
  }

  command -v "$PY" >/dev/null 2>&1 || {
    echo "ERROR: Python not found: $PY" >&2
    return 1
  }

  cd "$DIR" || {
    echo "ERROR: Cannot change to directory: $DIR" >&2
    return 1
  }

  touch "$LOG" 2>/dev/null || true

  if command -v nohup >/dev/null 2>&1; then
    nohup sh -c '
      LOOP_PIDFILE="$1"
      PY_BIN="$2"
      SCRIPT_PATH="$3"
      LOOP_INTERVAL="$4"
      loop_pid="$$"

      cleanup() {
        if [ -f "$LOOP_PIDFILE" ] && [ "$(cat "$LOOP_PIDFILE" 2>/dev/null)" = "$loop_pid" ]; then
          rm -f "$LOOP_PIDFILE"
        fi
        exit 0
      }

      trap cleanup INT TERM HUP EXIT

      while :; do
        "$PY_BIN" "$SCRIPT_PATH"
        sleep "$LOOP_INTERVAL"
      done
    ' sh "$PIDFILE" "$PY" "$SCRIPT" "$INTERVAL" >>"$LOG" 2>&1 </dev/null &
  else
    sh -c '
      LOOP_PIDFILE="$1"
      PY_BIN="$2"
      SCRIPT_PATH="$3"
      LOOP_INTERVAL="$4"
      loop_pid="$$"

      cleanup() {
        if [ -f "$LOOP_PIDFILE" ] && [ "$(cat "$LOOP_PIDFILE" 2>/dev/null)" = "$loop_pid" ]; then
          rm -f "$LOOP_PIDFILE"
        fi
        exit 0
      }

      trap cleanup INT TERM HUP EXIT

      while :; do
        "$PY_BIN" "$SCRIPT_PATH"
        sleep "$LOOP_INTERVAL"
      done
    ' sh "$PIDFILE" "$PY" "$SCRIPT" "$INTERVAL" >>"$LOG" 2>&1 </dev/null &
  fi

  pid="$!"
  echo "$pid" > "$PIDFILE"
  sleep 1

  if kill -0 "$pid" 2>/dev/null; then
    echo "STARTED (pid $pid)"
    return 0
  fi

  rm -f "$PIDFILE"
  echo "FAILED TO START" >&2
  return 1
}

stop() {
  if ! is_running; then
    rm -f "$PIDFILE"
    echo "STOPPED"
    return 0
  fi

  pid="$(cat "$PIDFILE" 2>/dev/null)"
  kill "$pid" 2>/dev/null || true

  i=0
  while [ "$i" -lt "$STOP_TIMEOUT" ]; do
    if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$PIDFILE"
      echo "STOPPED"
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done

  kill -9 "$pid" 2>/dev/null || true
  sleep 1

  if kill -0 "$pid" 2>/dev/null; then
    echo "FAILED TO STOP (pid $pid still running)" >&2
    return 1
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
  touch "$LOG" 2>/dev/null || true
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
