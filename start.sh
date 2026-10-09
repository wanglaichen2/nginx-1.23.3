#!/usr/bin/env bash
# Portable start: all paths relative to this script (nginx install root).
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
  echo "        Put this script inside the nginx install root."
  exit 1
fi

mkdir -p logs
[[ -f logs/error.log ]] || : > logs/error.log
[[ -f logs/access.log ]] || : > logs/access.log

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

watch_logs() {
  echo
  echo "============================================================"
  echo " Live logs: access.log + error.log  (prefixed)"
  echo " Ctrl+C only closes this watcher — nginx keeps running."
  echo " To stop nginx: run ./stop.sh in another window."
  echo "============================================================"
  echo
  echo "[tip] error.log often quiet when healthy; access.log updates on each visit."
  echo

  echo "[tail] last 15 lines of each, then follow both..."
  echo
  for f in logs/access.log logs/error.log; do
    echo "======== $f ========"
    tail -n 15 "$f" 2>/dev/null || true
    echo
  done
  echo "[follow] waiting for new log lines..."
  # Prefer multitail-less follow of both files
  if tail -F logs/access.log logs/error.log >/dev/null 2>&1 & then
    wait $! 2>/dev/null || true
  fi
  # Interactive follow (blocks until Ctrl+C)
  trap 'echo; echo "[INFO] Log watcher stopped. nginx may still be running — use ./stop.sh to quit."; exit 0' INT TERM
  tail -n 0 -F logs/access.log logs/error.log
}

if is_running; then
  echo "[WARN] nginx already running — attach to logs only."
  watch_logs
  exit 0
fi

echo "[INFO] Starting nginx from:"
echo "       $SCRIPT_DIR"

# Background start; cwd must be install root (conf / logs / html are relative)
"$NGINX_BIN" &
sleep 1

if ! is_running; then
  echo "[ERROR] nginx did not stay up. Last error.log:"
  echo "----------------------------------------"
  tail -n 30 logs/error.log 2>/dev/null || true
  echo "----------------------------------------"
  echo "Tip: run  $NGINX_BIN -t  in this folder to check conf/nginx.conf"
  exit 3
fi

echo "[OK] nginx started."
echo "     Default page: http://localhost:80"
echo "     Config:       conf/nginx.conf"

watch_logs
exit 0
