#!/usr/bin/env bash
# Build Caddy with the Cloudflare DNS module into host/build/caddy.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
mkdir -p build
# Only the output directory is mounted; no credentials are exposed to the builder.
docker run --rm --name caddy-cloudflare-build \
  --cpus=4 --memory=3g \
  -v "$PWD/build:/output:Z" \
  caddy:2-builder \
  xcaddy build v2.11.7 \
    --with github.com/caddy-dns/cloudflare \
    --output /output/caddy
./build/caddy version
./build/caddy list-modules | grep -x dns.providers.cloudflare
