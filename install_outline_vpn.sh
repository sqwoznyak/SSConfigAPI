#!/bin/bash

# Установка необходимых компонентов
sudo apt-get update
sudo apt-get install -y curl

# Скачивание и запуск скрипта установки Outline, сохранение вывода в переменную
output=$(bash -c "$(curl -sS https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh)")

# Вывод только нужной строки, содержащей уникальный идентификатор
echo "$output" | grep "apiUrl"
