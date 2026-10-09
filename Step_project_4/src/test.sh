#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SUFFIX="$(date +%s)-$$"
TEST_NETWORK="stepproject4-test-$SUFFIX"
MYSQL_CONTAINER="stepproject4-mysql-test-$SUFFIX"
TEST_IMAGE="${1:-stepproject4-test:$SUFFIX}"
NETWORK_CREATED=0
MYSQL_CREATED=0
IMAGE_CREATED=0

cleanup() {
  if [ "$MYSQL_CREATED" -eq 1 ]; then
    docker rm -f -v "$MYSQL_CONTAINER" >/dev/null 2>&1 || true
  fi
  if [ "$NETWORK_CREATED" -eq 1 ]; then
    docker network rm "$TEST_NETWORK" >/dev/null 2>&1 || true
  fi
  if [ "$IMAGE_CREATED" -eq 1 ]; then
    docker image rm "$TEST_IMAGE" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [ "$#" -eq 0 ]; then
  docker buildx build --provenance=false --sbom=false --load \
    -t "$TEST_IMAGE" "$SCRIPT_DIR/forStep4"
  IMAGE_CREATED=1
fi
docker network create "$TEST_NETWORK" >/dev/null
NETWORK_CREATED=1
docker run -d --name "$MYSQL_CONTAINER" \
  --network "$TEST_NETWORK" --network-alias mysql \
  -e MYSQL_DATABASE=shop -e MYSQL_USER=petshop \
  -e MYSQL_PASSWORD=hard_passw0rd -e MYSQL_ROOT_PASSWORD=test-root-pass \
  mysql:8.4 >/dev/null
MYSQL_CREATED=1

attempt=0
until docker exec -e MYSQL_PWD=hard_passw0rd "$MYSQL_CONTAINER" \
  mysql -h 127.0.0.1 -u petshop shop -e 'SELECT 1' >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 90 ]; then
    docker logs "$MYSQL_CONTAINER"
    echo "Test MySQL was not ready within 180 seconds." >&2
    exit 1
  fi
  sleep 2
done

docker run --rm --network "$TEST_NETWORK" \
  -e DB_HOST=mysql -e DB_USER=petshop \
  -e DB_PASSWORD=hard_passw0rd -e DB_NAME=shop \
  --entrypoint python "$TEST_IMAGE" \
  -m unittest discover -s tests -v
