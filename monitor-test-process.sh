#!/bin/bash

# ============================================================================
# Мониторинг процесса 'test' с отправкой HTTPS-запроса и логированием событий
# Запускается раз в минуту через systemd timer
# ============================================================================

set -euo pipefail  # Строгий режим: выход при ошибках, неопределённых переменных и т.д.

# --- Настройки ---
readonly PROCESS_NAME="test"
readonly MONITORING_URL="https://test.com/monitoring/test/api"
readonly LOG_FILE="/var/log/monitoring/monitoring.log"
readonly PID_FILE="/var/lib/monitor-test/last.pid"
readonly TIMEOUT_SEC=10

# --- Проверка зависимостей ---
for cmd in curl pgrep; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "ERROR: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

# --- Вспомогательная функция логирования ---
log_message() {
    local msg="$1"
    # Используем >> с блокировкой, чтобы избежать конфликтов при параллельной записи
    {
        flock -x 200
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $$ - $msg" >> "$LOG_FILE"
    } 200>"$LOG_FILE.lock"
}

# --- Создание директорий с правильными правами ---
# Выполняется один раз при первом запуске (обычно через post-install или вручную)
# Но на всякий случай проверим:
install -d -m 0755 -o monitor-test -g monitor-test "$(dirname "$LOG_FILE")"
install -d -m 0700 -o monitor-test -g monitor-test "$(dirname "$PID_FILE")"

# --- Проверка: запущен ли процесс? ---
if pgrep -x "$PROCESS_NAME" > /dev/null; then
    CURRENT_PID=$(pgrep -x "$PROCESS_NAME" | head -n1)  # берём первый PID, если их несколько

    # Чтение предыдущего PID (если файл существует)
    if [ -f "$PID_FILE" ]; then
        PREVIOUS_PID=$(cat "$PID_FILE" 2>/dev/null || echo "")
    else
        PREVIOUS_PID=""
    fi

    # Проверка на перезапуск
    if [ "$CURRENT_PID" != "$PREVIOUS_PID" ]; then
        log_message "Process '$PROCESS_NAME' restarted (PID: $CURRENT_PID)"
        echo "$CURRENT_PID" > "$PID_FILE"
        chmod 600 "$PID_FILE"
    fi

    # Отправка HTTPS-запроса
    if curl -s --max-time "$TIMEOUT_SEC" --output /dev/null --fail "$MONITORING_URL"; then
        # Успех — ничего не логируем (по ТЗ)
        :
    else
        CURL_EXIT_CODE=$?
        log_message "Failed to reach monitoring server ($MONITORING_URL). curl exit code: $CURL_EXIT_CODE"
    fi
else
    # Процесс не запущен — ничего не делаем (по ТЗ)
    :
fi