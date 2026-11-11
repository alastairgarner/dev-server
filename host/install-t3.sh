#!/usr/bin/env bash
# Run T3 Code as a user service on 127.0.0.1:3773, behind Caddy.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
if [[ $(id -u) -eq 0 ]]; then
  echo 'Run this as your normal user, not with sudo.' >&2
  exit 1
fi

# Keep this user's systemd services running at boot and after logout.
sudo loginctl enable-linger "$(id -un)"

mkdir -p "$HOME/.t3"
envfile="$HOME/.t3/service.env"
if [[ -e "$envfile" ]]; then
  echo "$envfile already exists; leaving it unchanged."
  echo 'Ensure T3CODE_HOST=127.0.0.1 and T3CODE_PORT=3773 are set there.'
else
  (umask 077; printf 'T3CODE_HOST=127.0.0.1\nT3CODE_PORT=3773\n' > "$envfile")
fi

# Use the official installer as the normal user, never root.
"$HOME/.local/bin/t3" service install
"$HOME/.local/bin/t3" service status
printf '\nService installed. Caddy routes https://code.%s here.\n' "$HOST_DOMAIN"
