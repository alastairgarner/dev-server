#!/usr/bin/env bash
# Print the Caddyfile for this machine. Values are rendered literally because
# caddy-preview adapts /etc/caddy/Caddyfile outside the Caddy service's env.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
envsubst '${TAILSCALE_IP} ${HOST_DOMAIN}' < "$host_dir/Caddyfile.template"
