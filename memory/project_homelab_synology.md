---
name: homelab-synology
description: Synology DS1618+ runs self-hosted services in Docker; tailnet-private; uses vheissulabs.com via Cloudflare DNS + DSM reverse proxy + acme.sh wildcard cert
metadata:
  type: project
---

Karl's homelab setup as of 2026-05.

## Hardware

- **Synology DS1618+**, 16GB RAM, DSM 7.2.2, Denverton x86 CPU. SSH as `karlm@synology` (Tailscale MagicDNS short name).
- Tailscale IP: `100.121.216.97`. Tailnet domain: `tail01309a.ts.net`.

## Domain & DNS

- Domain `vheissulabs.com` hosted on Cloudflare (DNS authoritative).
- Subdomain pattern: `<service>.vheissulabs.com` → A record (DNS-only / grey cloud) → `100.121.216.97`. Traffic only reachable via tailnet because the IP is CGNAT, not publicly routable.
- Pi-hole runs on the Synology for LAN DNS, but the canonical record for `vheissulabs.com` subdomains lives in Cloudflare so it works even if Pi-hole is down.
- Other dumb domains owned: `backwithsnacks.com` (unused, available for future projects).

## Cert management

- **Wildcard cert** for `*.vheissulabs.com` issued via Let's Encrypt DNS-01 challenge using Cloudflare API.
- DSM's built-in LE flow CANNOT do wildcards (Synology only allows wildcards for their own DDNS domains) AND rejects domains resolving to private IPs in its pre-flight check — so we use `neilpang/acme.sh` in Docker instead.
- acme.sh container at `/volume1/docker/acme.sh/` (docker-compose.yml + .env with CF token, Account ID, DSM creds).
- Container runs in `daemon` mode → auto-renews + redeploys to DSM on schedule.
- Deploy hook `synology_dsm` requires `SYNO_USE_TEMP_ADMIN=0` when running from a container (the temp-admin trick only works on the host) AND `HTTPS_INSECURE=1` (DSM uses self-signed for its admin UI).
- DSM cert mapping: after upload, must manually map the cert to each reverse-proxy hostname in Control Panel → Security → Certificate → Settings.

## Docker on Synology specifics

- Container Manager (renamed Docker package). Binary path: `/var/packages/ContainerManager/target/usr/bin/docker`. Not on PATH for SSH sessions.
- `karlm` user is in the `docker` group → no sudo needed for docker commands.
- All docker-compose stacks live under `/volume1/docker/<service>/`. Existing: `pihole`, `zensync`, `gitlab`, `gitlab-runner`, `acme.sh`.
- DSM owns ports 80/443 on all interfaces (0.0.0.0). Containers wanting those ports MUST use DSM's reverse proxy as a frontend — direct binding will collide.
- Container-to-host networking: use `host.docker.internal` with `extra_hosts: ["host.docker.internal:host-gateway"]` in compose (Linux Docker doesn't auto-resolve it).

## Reverse-proxy pattern

For every new self-hosted service:

1. Cloudflare DNS: `<service>` A → `100.121.216.97` (DNS-only).
2. Drop the service's docker-compose under `/volume1/docker/<service>/`. Bind it to a non-80/443 host port (e.g., 8080).
3. DSM → Login Portal → Advanced → Reverse Proxy → Create: source `https://<service>.vheissulabs.com:443`, destination `http://localhost:<port>`. Enable WebSocket headers under Custom Headers tab.
4. DSM → Security → Certificate → Settings → map `<service>.vheissulabs.com` to the wildcard cert.
5. If the service has its own external-URL config (like GitLab), point it at `https://<service>.vheissulabs.com` and disable its internal SSL/LE handling (DSM does termination).

## GitLab specifics

- **External URL**: `https://gitlab.vheissulabs.com`. Compose at `/volume1/docker/gitlab/docker-compose.yml`.
- GitLab is being **evaluated** as a potential GitHub replacement for freelance work (per [[zen-profiles]] context, Karl freelances + works at NotaryDash). Scope: code hosting + CI for personal projects, NOT a wiki/HRIS/everything tool — the user has explicitly bad memories of GitLab-as-everything-app at a previous company.
- Key GITLAB_OMNIBUS_CONFIG settings: `external_url 'https://gitlab.vheissulabs.com'`, `nginx['listen_port'] = 80` (must override because non-standard external_url port collides with Puma), `nginx['listen_https'] = false` (TLS done by DSM), `letsencrypt['enable'] = false`, `puma['worker_processes'] = 2`, `sidekiq['max_concurrency'] = 10`, prometheus/kas/registry disabled. **DO NOT set `grafana['enable']`** — removed in GitLab 16+, will crash chef.
- Boot time is ~5 min from cold (Ruby preloading is slow on Denverton CPU). Steady-state is fine.
- GitLab Runner container on same Docker network, uses host docker socket (`/var/run/docker.sock`) as Docker executor. Registration pending — needs auth token from Admin → CI/CD → Runners.

## Future access

- Currently tailnet-only via CGNAT IP. To add public access without changing the topology: swap the Cloudflare A record for a Cloudflare Tunnel CNAME (cloudflared container). No port forwarding, no static IP needed. Cloudflare Access can layer OAuth auth on top.
