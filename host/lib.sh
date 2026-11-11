# Sourced by the scripts here: load and check this machine's values.
host_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ! -f "$host_dir/host.env" ]]; then
  echo "Missing $host_dir/host.env; copy host.env.example and fill it in." >&2
  exit 1
fi
set -a
# shellcheck source=/dev/null
source "$host_dir/host.env"
set +a
: "${TAILSCALE_IP:?set TAILSCALE_IP in host.env}"
: "${HOST_DOMAIN:?set HOST_DOMAIN in host.env}"
