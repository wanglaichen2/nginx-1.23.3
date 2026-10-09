#!/usr/bin/env bash
# Portable stop: all paths relative to this script (nginx install root).
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

if [[ -f "./nginx.exe" ]]; then
  NGINX_BIN="./nginx.exe"
elif [[ -f "./nginx" ]]; then
  NGINX_BIN="./nginx"
else
  echo "[ERROR] nginx binary not found:"
  echo "        $SCRIPT_DIR/nginx.exe  (or nginx)"
  exit 1
fi

is_running() {
  if command -v tasklist >/dev/null 2>&1; then
    tasklist //FI "IMAGENAME eq nginx.exe" 2>/dev/null | grep -qi "nginx.exe"
    return $?
  fi
  if [[ -f logs/nginx.pid ]]; then
    local pid
    pid="$(tr -d '[:space:]' < logs/nginx.pid)"
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && return 0
  fi
  pgrep -x nginx >/dev/null 2>&1 && return 0
  pgrep -x nginx.exe >/dev/null 2>&1 && return 0
  return 1
}

force_kill() {
  if command -v taskkill >/dev/null 2>&1; then
    taskkill //F //T //IM nginx.exe >/dev/null 2>&1 || true
    return
  fi
  if [[ -f logs/nginx.pid ]]; then
    local pid
    pid="$(tr -d '[:space:]' < logs/nginx.pid)"
    [[ -n "$pid" ]] && kill -9 "$pid" 2>/dev/null || true
  fi
  pkill -9 -x nginx 2>/dev/null || true
  pkill -9 -x nginx.exe 2>/dev/null || true
}

if ! is_running; then
  echo "[INFO] nginx is not running."
  exit 0
fi

echo "[INFO] Sending quit signal (nginx -s quit) ..."
if ! "$NGINX_BIN" -s quit; then
  echo "[WARN] quit failed, trying nginx -s stop ..."
  "$NGINX_BIN" -s stop || true
fi

sleep 1
if ! is_running; then
  echo "[OK] nginx stopped."
  exit 0
fi

echo "[WARN] Still running, force kill ..."
force_kill
sleep 1

if ! is_running; then
  echo "[OK] nginx force-stopped."
  exit 0
fi

echo "[ERROR] Failed to stop nginx"
exit 2
