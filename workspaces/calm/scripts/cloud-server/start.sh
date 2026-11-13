#!/usr/bin/env bash
# Per-boot startup for the CALM development environment.
# Restarts the Docker daemon (with the nested-container network fixes), brings
# the compose services back up against the persisted volumes, and reconciles
# the database. Dependencies and images already live on disk from `install`.
set -euo pipefail
cd "$(dirname "$0")/../../.."

bash .cursor/scripts/cloud-server/docker-daemon-up.sh

if [ ! -f .env ]; then
  cp .env_example .env
  grep -q '^USE_VIS=' .env || echo 'USE_VIS=false' >>.env
  sed -i "s/^USER_ID=.*/USER_ID=$(id -u)/" .env || true
fi

echo "== Starting services =="
sudo docker compose up -d
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0 >/dev/null 2>&1 || true
sudo iptables-legacy -P FORWARD ACCEPT 2>/dev/null || true

for _ in $(seq 1 30); do
  sudo docker compose exec -T app true >/dev/null 2>&1 && break
  sleep 2
done

echo "== Reconciling the database =="
sudo docker compose exec -T app docker/setup.sh true

echo "== Services ready =="
