# Мониторинг процесса test

Скрипт для мониторинга процесса test в Linux.

## Что умеет:
- Проверяет раз в минуту, запущен ли процесс test.
- Если процесс перезапущен → пишет запись в лог /var/log/monitoring.log.
- Если процесс работает → делает HTTPS-запрос к https://test.com/monitoring/test/api.
- Если сервер недоступен → пишет ошибку в лог.

## Установка

`bash
# Скопировать скрипт
sudo cp monitor_test.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/monitor_test.sh

# Создать каталоги и лог
sudo mkdir -p /var/lib/monitoring
sudo touch /var/log/monitoring.log
sudo chmod 644 /var/log/monitoring.log

# Установить systemd-юниты
sudo cp systemd/monitor-test.* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now monitor-test.timer