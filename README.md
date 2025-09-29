Написать скрипт на bash для мониторинга процесса test в среде
linux. Скрипт должен отвечать следующим требованиям:
1. Запускаться при запуске системы (предпочтительно написать юнит
systemd в дополнение к скрипту)
2. Отрабатывать каждую минуту
3. Если процесс запущен, то стучаться(по https) на
https://test.com/monitoring/test/api  
4. Если процесс был перезапущен, писать в лог /var/log/monitoring.log
(если процесс не запущен, то ничего не делать)
5. Если сервер мониторинга не доступен, так же писать в лог

6. Создадим отдельного пользователя что бы скрипт запускался не от рута.
7. sudo useradd --system --home /var/lib/monitor-test --shell /usr/sbin/nologin monitor-test
8. Этот пользователь:
Не может входить в систему (nologin);
Имеет домашнюю директорию /var/lib/monitor-test (стандарт для системных сервисов).

Создадим скрипт сохраним его как /usr/local/bin/monitor-test-process.sh
Используется install -d для безопасного создания директорий с нужными владельцем и правами.
flock предотвращает повреждение лога при одновременной записи (маловероятно, но возможно).
set -euo pipefail делает скрипт более надёжным.

Сделаем скрипт исполняемым sudo chmod +x /usr/local/bin/monitor-test-process.sh

Создадим systemd service /etc/systemd/system/monitor-test-process.service

Создадим таймер /etc/systemd/system/monitor-test-process.timer

Применение и проверка
# Перезагрузить конфигурацию systemd
sudo systemctl daemon-reload
# Включить и запустить таймер
sudo systemctl enable --now monitor-test-process.timer
# Проверить статус
systemctl status monitor-test-process.timer
journalctl -u monitor-test-process.service -n 20 --no-pager
# Проверить лог-файл
sudo tail -f /var/log/monitoring/monitoring.log

Так как большого опыта в написании баш скриптов не имею, воспользовался ИИ Qwen.

