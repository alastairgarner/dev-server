#!/usr/bin/env bash
# Install the custom Caddy binary, Caddyfile and systemd override.
# Keeps Fedora's caddy package for its service and user.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
cd -- "$host_dir"

sudo -v
if ! sudo test -f /etc/caddy/cloudflare.env; then
  echo 'Create /etc/caddy/cloudflare.env with CF_DNS_API_TOKEN first (see README).' >&2
  exit 1
fi
if [[ ! -x build/caddy ]]; then
  echo 'Build missing. Run build-caddy.sh and wait for it to finish successfully.' >&2
  exit 1
fi
./build/caddy list-modules | grep -x 'dns.providers.cloudflare'

rendered=$(mktemp)
trap 'rm -f "$rendered"' EXIT
./render-caddyfile.sh > "$rendered"

sudo install -m 0755 build/caddy /usr/local/bin/caddy
sudo restorecon /usr/local/bin/caddy

if ! sudo test -e /etc/caddy/Caddyfile.backup; then
  sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup
fi
sudo install -m 0644 "$rendered" /etc/caddy/Caddyfile
sudo mkdir -p /etc/systemd/system/caddy.service.d
sudo install -m 0644 caddy-override.conf /etc/systemd/system/caddy.service.d/override.conf

sudo systemctl daemon-reload
sudo systemctl enable --now caddy
sudo systemctl restart caddy
sudo systemctl --no-pager --full status caddy
