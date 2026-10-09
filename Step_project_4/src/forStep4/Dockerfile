FROM python:3.11-slim

WORKDIR /app
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000
# The original app shares one MySQL connection, so serve one request at a time
# in each Pod. Kubernetes runs two Pods for the assignment.
CMD ["flask", "--app", "app", "run", "--host=0.0.0.0", "--port=5000", "--without-threads"]
