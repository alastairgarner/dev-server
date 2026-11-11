#!/usr/bin/env bash
# Allow HTTPS to Caddy from the Tailscale network only.
#   firewall.sh --test   add the rule for five minutes
#   firewall.sh          add it permanently (survives reboot)
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
rule="rule family=\"ipv4\" source address=\"100.64.0.0/10\" destination address=\"$TAILSCALE_IP\" port port=\"443\" protocol=\"tcp\" accept"

if [[ ${1-} == --test ]]; then
  sudo firewall-cmd --add-rich-rule="$rule" --timeout=300
  printf '\nTemporary HTTPS rule added for five minutes.\nRetry from another device: curl -I https://sync.%s\n' "$HOST_DOMAIN"
  exit 0
fi

zone=$(sudo firewall-cmd --get-default-zone)
sudo firewall-cmd --permanent --zone="$zone" --add-rich-rule="$rule"
# Replace any temporary rule without reloading unrelated firewall configuration.
if sudo firewall-cmd --zone="$zone" --query-rich-rule="$rule" >/dev/null; then
  sudo firewall-cmd --zone="$zone" --remove-rich-rule="$rule"
fi
sudo firewall-cmd --zone="$zone" --add-rich-rule="$rule"
printf '\nHTTPS rule is active without expiry and saved for reboot (zone: %s).\n' "$zone"
