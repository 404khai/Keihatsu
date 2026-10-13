#!/bin/sh
set -eu
umask 077
cd "${KEIHATSU_DEPLOY_DIR:-/opt/keihatsu/deploy/netcup}"
backup_root=${KEIHATSU_BACKUP_DIR:-/var/backups/keihatsu}
mkdir -p "$backup_root"
exec 9>"$backup_root/.lock"
flock -n 9 || exit 0
stamp=$(date -u +%Y%m%dT%H%M%SZ)
partial="$backup_root/.${stamp}.partial"
mkdir "$partial"
trap 'rm -rf "$partial"' EXIT INT TERM
docker compose exec -T db pg_dump -U keihatsu -d keihatsu -Fc > "$partial/database.dump"
docker compose exec -T db pg_restore --list < "$partial/database.dump" > /dev/null
# Downloads are a regenerable cache; uploads and configuration are durable.
docker compose exec -T api tar -czf - -C /app uploads > "$partial/uploads.tar.gz"
tar -czf "$partial/config.tar.gz" .env secrets compose.yaml Caddyfile
mv "$partial" "$backup_root/$stamp"
find "$backup_root" -mindepth 1 -maxdepth 1 -type d -name '20*T*Z' -mtime +14 -exec rm -rf {} +
printf 'Backup completed: %s/%s\n' "$backup_root" "$stamp"
