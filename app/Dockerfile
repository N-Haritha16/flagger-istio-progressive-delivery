FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

ENV APP_VERSION=v1 \
    APP_MODE=stable \
    FAULT_RATE=0.0 \
    EXTRA_LATENCY=0.0

EXPOSE 8080

CMD ["gunicorn", "-b", "0.0.0.0:8080", "src.main:app"]
