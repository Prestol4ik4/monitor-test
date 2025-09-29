#!/usr/bin/env bash

PROCESS_NAME="test"
API_URL="https://test.com/monitoring/test/api"
LOG_FILE="/var/log/monitoring.log"
STATE_DIR="/var/lib/monitoring"
STATE_PID_FILE="$STATE_DIR/${PROCESS_NAME}.pid"
LOCKFILE="/var/lock/monitor_${PROCESS_NAME}.lock"
CURL_TIMEOUT=10

log() {
  local lvl="$1"; shift
  local msg="$*"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "${ts} ${lvl} ${msg}" >> "$LOG_FILE"
}

# создаём каталог для стейта
mkdir -p "$STATE_DIR"

# создаём лог, если его нет
touch "$LOG_FILE"

# блокировка — чтобы не запускался второй экземпляр одновременно
exec 9>"$LOCKFILE" 2>/dev/null || exit 0
if ! flock -n 9 ; then
  exit 0
fi

# ищем процесс test
CURRENT_PID="$(pgrep -x "$PROCESS_NAME" | head -n1 || true)"

# если процесс не найден
if [ -z "$CURRENT_PID" ]; then
  rm -f "$STATE_PID_FILE"
  exit 0
fi

# проверка на перезапуск
PREV_PID=""
if [ -f "$STATE_PID_FILE" ]; then
  PREV_PID="$(cat "$STATE_PID_FILE" 2>/dev/null || true)"
fi

if [ -n "$PREV_PID" ] && [ "$PREV_PID" != "$CURRENT_PID" ]; then
  log "INFO" "Процесс '$PROCESS_NAME' перезапущен: previous_pid=$PREV_PID current_pid=$CURRENT_PID"
fi

# сохраняем текущий PID
echo "$CURRENT_PID" > "$STATE_PID_FILE"

# запрос к API
HTTP_CODE="$(curl --silent --show-error --fail --max-time "$CURL_TIMEOUT" \
  -o /dev/null -w "%{http_code}" "$API_URL" 2>/dev/null || echo "000")"

if [[ "$HTTP_CODE" =~ ^2 ]]; then
   exit 0
else
  log "ERROR" "Мониторинг-сервер недоступен или вернул код $HTTP_CODE для $API_URL"
fi

exit 0