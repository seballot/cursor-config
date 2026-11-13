#!/usr/bin/env bash
# Bring up a Docker Engine suitable for running the CALM docker-compose stack
# inside a Cloud Agent VM (nested containers). Idempotent: safe to run on every
# boot. Installs Docker only when missing, then (re)starts the daemon and
# reapplies the network tweaks that nested containers need.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- 1. Install Docker Engine + Compose plugin if not already present ---------
# On a build snapshot Docker is already installed, so this whole block is
# skipped and only the daemon start + network fixes below run.
if ! command -v docker >/dev/null 2>&1; then
  echo "== Installing Docker Engine =="
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo -E apt-get update -qq
  # force-conf* keeps the run non-interactive (fuse3 ships an /etc/fuse.conf prompt)
  sudo -E apt-get install -y -qq \
    -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
    docker-compose-plugin fuse-overlayfs iptables
fi

# --- 2. Configure the daemon for a nested (overlay-on-overlay) filesystem ------
# The VM root fs is already an overlay mount, so Docker's default overlay
# snapshotter cannot mount another overlay. fuse-overlayfs works in userspace.
sudo mkdir -p /etc/docker
if [ ! -f /etc/docker/daemon.json ] || ! grep -q fuse-overlayfs /etc/docker/daemon.json; then
  echo '{
  "features": { "containerd-snapshotter": false },
  "storage-driver": "fuse-overlayfs"
}' | sudo tee /etc/docker/daemon.json >/dev/null
fi

# --- 3. Start dockerd (no systemd in the VM, so launch it detached) -----------
if ! sudo docker info >/dev/null 2>&1; then
  echo "== Starting dockerd =="
  sudo rm -f /var/run/docker.pid /var/run/docker.sock
  # setsid + nohup fully detaches dockerd into its own session so it survives
  # the exit of whatever launched this script (install/start/terminal).
  sudo bash -c 'setsid nohup dockerd >/var/log/dockerd.log 2>&1 < /dev/null &' || true
  for _ in $(seq 1 30); do
    sudo docker info >/dev/null 2>&1 && break
    sleep 2
  done
fi
if ! sudo docker info >/dev/null 2>&1; then
  echo "dockerd failed to start; last log lines:" >&2
  sudo tail -n 30 /var/log/dockerd.log >&2 || true
  exit 1
fi

# --- 4. Network fixes for nested containers (not persisted across boots) -------
# a) Let bridged container<->container traffic bypass the host iptables hooks.
# b) The base VM ships a legacy-iptables FORWARD policy of DROP; Docker writes
#    its rules to the nft backend, so open the legacy FORWARD chain to allow
#    container egress and inter-container traffic.
sudo modprobe br_netfilter 2>/dev/null || true
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0 >/dev/null 2>&1 || true
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=0 >/dev/null 2>&1 || true
sudo iptables-legacy -P FORWARD ACCEPT 2>/dev/null || true

echo "Docker is ready ($(sudo docker --version))"
