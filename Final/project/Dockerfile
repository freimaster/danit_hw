FROM python:3.14-slim

ARG APP_REVISION=dev
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    APP_REVISION=${APP_REVISION}

WORKDIR /app
COPY --chown=10001:10001 app/server.py ./server.py
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/', timeout=2)"
CMD ["python", "server.py"]
