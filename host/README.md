# Host setup

Setup for the machine this stack runs on, not the portable services in the
parent directory. It serves Syncthing, T3 Code, metrics and `caddy-preview`
routes over HTTPS to the Tailscale network only:

| Name | Upstream |
| --- | --- |
| `sync.<HOST_DOMAIN>` | Syncthing, 127.0.0.1:8384 |
| `code.<HOST_DOMAIN>` | T3 Code, 127.0.0.1:3773 |
| `metrics.<HOST_DOMAIN>` | 127.0.0.1:8090 |

Caddy binds to the Tailscale IP and gets certificates with a Cloudflare DNS
challenge, so nothing is exposed publicly. DNS for `*.<HOST_DOMAIN>` points at
the Tailscale IP from the tailnet's own resolver (Pi-hole).

Machine values live in ignored `host.env`; the tracked files contain none.
Fedora, firewalld, Docker and Tailscale are assumed.

## Rebuild

1. `cp host.env.example host.env` and fill in `TAILSCALE_IP` and `HOST_DOMAIN`.
2. Create the Cloudflare token file (DNS edit, limited to the zone):
   ```sh
   sudo install -m 600 /dev/null /etc/caddy/cloudflare.env
   sudoedit /etc/caddy/cloudflare.env   # CF_DNS_API_TOKEN=...
   ```
3. `sudo dnf install caddy`, for its service and user.
4. `./build-caddy.sh`: builds Caddy with the Cloudflare module in Docker.
5. `./install-caddy.sh`: installs the binary at `/usr/local/bin/caddy`, the
   rendered Caddyfile and the systemd override.
6. `./firewall.sh --test`, check `curl -I https://sync.<HOST_DOMAIN>` from
   another device, then `./firewall.sh` to persist the rule.
7. `./install-t3.sh`: T3 Code as a lingering user service.
8. Run `preview init` from `caddy-preview`; the Caddyfile already imports
   `/etc/caddy/preview/current/Caddyfile`.

## Changing the Caddyfile

Edit `Caddyfile.template`, then check `./render-caddyfile.sh | diff -
/etc/caddy/Caddyfile` before installing. The live file holds literal values
because `caddy-preview` adapts it outside the Caddy service's environment.
