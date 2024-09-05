# Makefile для установки, настройки, запуска FastAPI-приложения и создания systemd службы

# Переменные
SERVICE_NAME = bot-outline-api
SERVICE_PATH = /etc/systemd/system/$(SERVICE_NAME).service
WORKING_DIR = /home/vpn/outline-gateway
VENV_PATH = $(WORKING_DIR)/env/bin
GUNICORN_CMD = $(VENV_PATH)/gunicorn
PORT = 5000
LOG_DIR = $(WORKING_DIR)/logs

# Устанавливает Python3 и pip
install:
	@echo "Устанавливаем Python3 и pip..."
	sudo apt-get update
	sudo apt-get install -y python3 python3-pip

# Устанавливает зависимости проекта из файла requirements.txt
requirements:
	@echo "Устанавливаем зависимости проекта..."
	pip3 install -r requirements.txt

# Создает виртуальное окружение для проекта
create_venv:
	@echo "Создаем виртуальное окружение..."
	python3 -m venv $(WORKING_DIR)/env

# Активирует виртуальное окружение и устанавливает зависимости
install_venv: create_venv
	@echo "Устанавливаем зависимости в виртуальном окружении..."
	$(VENV_PATH)/pip install -r requirements.txt

# Создает директорию для логов
create_logs_dir:
	@echo "Создаем директорию для логов..."
	mkdir -p $(LOG_DIR)

# Запускает скрипты установки NGINX и Outline VPN
install_services:
	@echo "Запускаем установку NGINX и Outline VPN..."
	./install_outline_vpn.sh
	./install_nginx_proxy.sh


# Запускает FastAPI приложение через Gunicorn
run: create_logs_dir
	@echo "Запускаем FastAPI сервер на порту $(PORT)..."
	$(GUNICORN_CMD) -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:$(PORT) --access-logfile $(LOG_DIR)/access.log --error-logfile $(LOG_DIR)/error.log main:app

# Создает файл службы systemd для FastAPI
create_service:
	@echo "Создаем systemd службу $(SERVICE_NAME)..."
	echo "[Unit]\n\
Description=Gunicorn daemon для FastAPI приложения\n\
After=network.target\n\n\
[Service]\n\
User=root\n\
Group=www-data\n\
WorkingDirectory=$(WORKING_DIR)\n\
Environment=\"PATH=$(VENV_PATH)\"\n\
ExecStart=$(GUNICORN_CMD) -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:$(PORT) main:app\n\
StandardOutput=append:$(LOG_DIR)/systemd_output.log\n\
StandardError=append:$(LOG_DIR)/systemd_error.log\n\n\
[Install]\n\
WantedBy=multi-user.target" | sudo tee $(SERVICE_PATH)

# Перезагружает systemd для применения изменений
reload_daemon:
	@echo "Перезагружаем systemd демоны..."
	sudo systemctl daemon-reload

# Включает службу для автоматического запуска при загрузке
enable_service:
	@echo "Включаем службу $(SERVICE_NAME) для автозапуска..."
	sudo systemctl enable $(SERVICE_NAME)

# Запускает службу
start_service: install_services
	@echo "Запускаем службу $(SERVICE_NAME)..."
	sudo systemctl start $(SERVICE_NAME)

# Останавливает службу
stop_service:
	@echo "Останавливаем службу $(SERVICE_NAME)..."
	sudo systemctl stop $(SERVICE_NAME)

# Выводит статус службы
status_service:
	@echo "Статус службы $(SERVICE_NAME):"
	sudo systemctl status $(SERVICE_NAME)

# Полная установка: устанавливает Python3, зависимости, создает виртуальное окружение, службу systemd и запускает приложение
setup: install requirements install_venv create_service reload_daemon enable_service start_service

# Очищает временные файлы и кеши
clean:
	@echo "Очищаем временные файлы и кеши..."
	rm -rf $(WORKING_DIR)/__pycache__
	rm -rf $(WORKING_DIR)/*.pyc
	rm -rf $(LOG_DIR)/*.log

# Выводит справку по использованию Makefile
help:
	@echo "Доступные команды Makefile:"
	@echo "  install          - Установка Python3 и pip"
	@echo "  requirements     - Установка зависимостей проекта"
	@echo "  create_venv      - Создание виртуального окружения"
	@echo "  install_venv     - Установка зависимостей в виртуальном окружении"
	@echo "  run              - Запуск FastAPI через Gunicorn"
	@echo "  create_service   - Создание systemd службы"
	@echo "  reload_daemon    - Перезагрузка systemd демонов"
	@echo "  enable_service   - Включение службы для автозапуска"
	@echo "  start_service    - Запуск службы"
	@echo "  stop_service     - Остановка службы"
