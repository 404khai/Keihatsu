#!/bin/sh
set -eu
cd /opt/keihatsu/deploy/netcup
: "${BETA_ADMIN_EMAIL:?Configure BETA_ADMIN_EMAIL in /etc/keihatsu-admin.env}"
# Only an account linked to a verified Google sign-in qualifies. psql quotes
# the email as a SQL literal; no account or password is created by this job.
result=$(docker compose exec -T db psql -U keihatsu -d keihatsu -qAt \
    -v ON_ERROR_STOP=1 -v admin_email="$BETA_ADMIN_EMAIL" <<'SQL'
UPDATE users SET role = 'ADMIN', "updatedAt" = NOW()
WHERE email = :'admin_email' AND "googleId" IS NOT NULL
RETURNING id;
SQL
)
if [ -n "$result" ]; then
    echo 'Verified beta account promoted; disabling the one-time promotion timer.'
    systemctl disable --now keihatsu-admin-promotion.timer
else
    echo 'Waiting for the beta administrator to sign in with Google.'
fi
