# Беремо легкий офіційний образ Python
FROM python:3.12-slim

# Встановлюємо робочу папку в контейнері
WORKDIR /app

# Копіюємо файл залежностей
COPY requirements.txt .

# Встановлюємо залежності
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код проекту в контейнер
COPY . .

# Відкриваємо 80 порт всередині контейнера
EXPOSE 80

# Запускаємо додаток через gunicorn на 80 порту
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:80", "main:app"]