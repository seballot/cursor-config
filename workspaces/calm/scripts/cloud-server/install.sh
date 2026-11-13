#!/usr/bin/env bash
# One-time (per build) setup of the CALM development environment.
# Builds the docker-compose images, installs Ruby/JS dependencies into the
# named volumes, builds frontend assets, and initialises the database.
# Idempotent: re-running converges to the same state.
set -euo pipefail
cd "$(dirname "$0")/../../.."

bash .cursor/scripts/cloud-server/docker-daemon-up.sh

# Local compose config. .env is git-ignored, so (re)create it from the example.
if [ ! -f .env ]; then
  cp .env_example .env
fi
# USE_VIS=false enables the simple dev login form (real login uses the VIS SSO).
grep -q '^USE_VIS=' .env || echo 'USE_VIS=false' >>.env
# Match the container user id to the agent user so bind-mounted files stay owned.
sed -i "s/^USER_ID=.*/USER_ID=$(id -u)/" .env || true

echo "== Building images =="
sudo docker compose build

echo "== Starting services =="
sudo docker compose up -d
# Reapply the network fixes now that the compose bridges exist.
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0 >/dev/null 2>&1 || true
sudo iptables-legacy -P FORWARD ACCEPT 2>/dev/null || true

# Wait until the app container is up before exec-ing into it.
for _ in $(seq 1 30); do
  sudo docker compose exec -T app true >/dev/null 2>&1 && break
  sleep 2
done

echo "== Installing Ruby gems (into the 'gems' volume) =="
# The development image does not bake gems in; they live in the named volume.
sudo docker compose exec -T app bash -lc 'bundle check || bundle install --jobs 4'

echo "== Installing JS deps + building assets (into the 'node_modules' volume) =="
sudo docker compose exec -T app bash -lc 'yarn install --frozen-lockfile'
sudo docker compose exec -T app bash -lc 'yarn build'

echo "== Preparing the database =="
# docker/setup.sh creates + schema-loads the DB on first run, then migrates.
sudo docker compose exec -T app docker/setup.sh true

echo "== Install complete =="
