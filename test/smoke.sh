#!/usr/bin/env bash
# Start the image and check the two endpoints. Usage: test/smoke.sh <image>
set -euo pipefail
image=${1:?image}
name=cm-smoke-$$
trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT

docker run -d --name "$name" "$image" >/dev/null
ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$name")
for i in $(seq 1 30); do
  curl -fsS -o /dev/null "http://$ip:8001/" 2>/dev/null && break
  sleep 1
done
curl -fsS "http://$ip:8001/" | grep -q running
code=$(curl -s -o /dev/null -w '%{http_code}' "http://$ip:8001/conferenceMapper?id=12345")
[ "$code" = 200 ] || { echo "conferenceMapper: HTTP $code" >&2; docker logs "$name" >&2; exit 1; }
[ "$(docker exec "$name" id -u)" != 0 ] || { echo "runs as root" >&2; exit 1; }
echo "smoke test passed"
