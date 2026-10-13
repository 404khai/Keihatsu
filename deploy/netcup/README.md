# Netcup beta deployment

Host: `159.195.86.119` (Debian 13). Application files: `/opt/keihatsu`.

The beta starts with a new PostgreSQL database. The current API origin is
`https://keihatsu.159.195.86.119.sslip.io`. This free DNS name resolves to the
server IP; it depends on sslip.io and should be replaced with an owned domain
for the public launch. Caddy issues and renews HTTPS certificates automatically.

## Deploy

Install Docker Engine and the Compose plugin using Docker's Debian instructions.
Copy `apps/api` and `deploy/netcup` to the same layout under `/opt/keihatsu`.
Exclude `.env`, `node_modules`, build outputs, local Chromium, and downloaded media.
Create `deploy/netcup/.env` from `.env.example`, generate fresh database and JWT
secrets, set integration credentials, and restrict the file to mode 600.
Use URL-safe hex for `POSTGRES_PASSWORD`, because it is embedded in DATABASE_URL.
Optional Firebase/APNs keys go in `deploy/netcup/secrets` and must be readable by
container UID 1000; never commit them.

```sh
cd /opt/keihatsu/deploy/netcup
./deploy.sh
docker compose ps
curl -f https://keihatsu.159.195.86.119.sslip.io/health
```

The deployment runs the locked npm install, Prisma generation, TypeScript build,
unit tests, and `prisma migrate deploy`. Failed tests stop deployment; failed
migrations prevent the API from starting. Docker restarts services after reboot.
The database has no host port; the API binds only to host loopback. Public ports
are SSH (22), HTTP (80), HTTPS (443 TCP/UDP). SSH password login is disabled after
verifying the existing workstation SSH key. Fail2ban protects SSH and unattended
security upgrades are enabled. The root password remains valid for console access.

## Clients and admin

- Flutter release builds use this origin by default. Override with
  `--dart-define=API_BASE_URL=https://api.keihatsu.app` after domain setup.
- Native iOS device/release builds use `KEIHATSU_API_BASE_URL` in Xcode; the
  Debug simulator retains its local development override.
- Set the Vercel project environment variable `API_URL` to this origin and
  redeploy the website. It is server-only. The backend permits CORS from
  `https://keihatsu.vercel.app`, `https://keihatsu.app`, and `https://www.keihatsu.app`.
- Google web sign-in requires `https://keihatsu.vercel.app` in the Google OAuth
  client's authorized JavaScript origins. Add the purchased website domain later.
- Google/Cloudinary/SMTP/Firebase credentials were copied from the existing local
  environment; end-to-end provider delivery still requires a real sign-in/device.
- No default admin account or password is seeded. the configured administrator signed in with Google
  and was promoted to ADMIN by a one-time systemd timer. The timer has disabled
  itself. Its email configuration is root-only in
  `/etc/keihatsu-admin.env`. For subsequent manual promotions, use:

```sh
docker compose exec api node dist/promote-user.js admin@example.com
```

## Backups and restore

`backup.sh` takes a PostgreSQL custom-format dump, an uploads archive, and a
configuration/credentials archive. Backups live in `/var/backups/keihatsu`, are
root-only, and retain about 14 days. Downloaded chapters are a regenerable cache
and are excluded. Install the systemd service/timer:

```sh
cp keihatsu-backup.service keihatsu-backup.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now keihatsu-backup.timer
systemctl start keihatsu-backup.service
systemctl list-timers keihatsu-backup.timer
```

These backups are on the same server. Copy them to an independent secure location
for recovery from server/disk loss. The configuration archive contains secrets.
To restore, stop API/Caddy, restore the dump into an empty database using
`pg_restore -U keihatsu -d keihatsu --exit-on-error`, restore uploads/config,
then run `docker compose up -d --wait`. Never restore over live beta writes.

## Add api.keihatsu.app later

1. Register the domain and add an A record: `api` → `159.195.86.119`.
2. Wait for public DNS to resolve. Avoid an AAAA record unless IPv6 routing is
   verified. If using a DNS proxy, initially use DNS-only for certificate setup.
3. Set `API_DOMAIN` in the server `.env` to
   `api.keihatsu.app, keihatsu.159.195.86.119.sslip.io` to serve both hostnames.
4. Run `docker compose up -d --force-recreate caddy`. Verify `/health` on the new
   HTTPS name. Keep the temporary hostname active until old builds are retired.
5. Update Flutter/iOS beta build settings and Vercel `API_URL`, then rebuild/
   redeploy the clients. Add new website origins in Google OAuth if needed.

Changing a hostname does not change the database, uploads, or account data.

## Operations

```sh
docker compose logs --tail=100 api
docker compose logs --tail=100 caddy
docker compose exec db psql -U keihatsu -d keihatsu
systemctl status keihatsu-backup.timer
```

Do not run `docker compose down -v`; that deletes persistent volumes. The server
`.env` is the source of deployed secrets. JWT rotation signs existing sessions out.
Swagger is disabled on the beta; `SWAGGER_ENABLED=true` enables `/docs` temporarily.
