#!/bin/bash

# Функция для проверки валидности доменного имени
validate_domain() {
    if [[ $1 =~ ^[a-zA-Z0-9.-]+$ ]]; then
        echo "Доменное имя валидно."
    else
        echo "Доменное имя невалидно. Введите корректное доменное имя."
        exit 1
    fi
}

# Функция для проверки порта
validate_port() {
    if [[ $1 =~ ^[0-9]+$ ]] && [ $1 -ge 1 ] && [ $1 -le 65535 ]; then
        echo "Порт валиден."
    else
        echo "Номер порта невалиден. Введите номер порта в диапазоне от 1 до 65535."
        exit 1
    fi
}

# Запрашиваем у пользователя доменное имя и порт
read -p "Введите доменное имя: " domain_name
validate_domain $domain_name

read -p "Введите порт внутреннего сервера (1-65535): " internal_port
validate_port $internal_port

# Обновление списка пакетов
sudo apt update

# Установка Nginx
sudo apt install -y nginx

# Проверка, успешно ли установлен Nginx
if ! which nginx > /dev/null; then
    echo "Ошибка установки Nginx. Проверьте вывод команды установки и попробуйте снова."
    exit 1
fi

# Создание файла proxy_params
sudo tee /etc/nginx/proxy_params <<EOF
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
EOF

# Настройка серверного блока
sudo tee /etc/nginx/sites-available/reverse-proxy <<EOF
server {
    listen 80;
    server_name $domain_name;

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:$internal_port;
    }
}
EOF

# Создание символической ссылки для активации конфигурации
sudo ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/reverse-proxy

# Удаление конфигурации default, если она не нужна
sudo rm -f /etc/nginx/sites-enabled/default

# Проверка конфигурации на ошибки
sudo nginx -t

# Перезапуск Nginx для применения новой конфигурации
sudo systemctl restart nginx

echo "Nginx установлен и настроен как обратный прокси для $domain_name на порту $internal_port. Проверьте работу прокси."
