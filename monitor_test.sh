#!/bin/bash

#Настройки
PROCESS_NAME="test"
LOG_FILE="/var/log/monitoring.log"
STATE_FILE="/var/lib/monitoring/state.pid"
URL="https://test.com/monitoring/test/api"

#Безопасные права
#Только владелец может читать и писать
umask 077

#Подготовка каталогов и файлов
mkdir -p /var/lib/monitoring

# Создаём файлы, если их нет
touch "$LOG_FILE" "$STATE_FILE"

# Устанавливаем владельца (пользователь и группа monitoring)
chown monitoring:monitoring "$LOG_FILE" "$STATE_FILE"

#Проверка процесса
current_pid=$(pgrep -o "$PROCESS_NAME")

# Если процесс не запущен — выходим без действий
if [[ -z "$current_pid" ]]; then
    exit 0
fi

#Проверка предыдущего состояния
if [[ -f "$STATE_FILE" ]]; then
    last_pid=$(cat "$STATE_FILE")
else
    last_pid=0
fi

#Если PID изменился — логируем перезапуск
if [[ "$current_pid" != "$last_pid" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Process '$PROCESS_NAME' restarted (PID: $current_pid)" >> "$LOG_FILE"
    echo "$current_pid" > "$STATE_FILE"
fi

#Проверка доступности сервера
if ! curl -fsS -o /dev/null "$URL"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Monitoring server not reachable: $URL" >> "$LOG_FILE"
fi
