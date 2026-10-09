#!/usr/bin/env bash
# Portable reload: all paths relative to this script (nginx install root).
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

if ! is_running; then
  echo "[ERROR] nginx is not running. Use ./start.sh first."
  exit 1
fi

echo "[INFO] Reloading conf/nginx.conf ..."
if ! "$NGINX_BIN" -s reload; then
  echo "[ERROR] reload failed. Check conf/nginx.conf syntax:"
  echo "        $NGINX_BIN -t"
  exit 2
fi

echo "[OK] reload sent."
exit 0
