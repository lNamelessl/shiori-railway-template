#!/bin/sh
# Shiori Railway template entrypoint.
#
# First boot (marker-guarded, non-destructive):
#   1. Run `shiori print` once so upstream's own initShiori() performs SQLite
#      migrations and seeds its documented default owner account (shiori/gopher)
#      on the empty database — before any network listener exists.
#   2. Replace that account's password with a per-deploy random one, so the
#      publicly documented "gopher" default is never servable on the internet.
#   3. Drop default-creds.txt into the volume (read via `railway ssh`).
#   4. Generate and persist a session-signing secret so logins survive restarts.
# Every later boot skips straight to the server.
#
# Runs as root (upstream image is root too), so Railway's root-owned volume
# mount needs no chown dance.
set -eu

DIR="${SHIORI_DIR:-/data}"
DB="$DIR/shiori.db"
MARKER="$DIR/.railway-seeded"
SECRET_FILE="$DIR/.railway-secret"
CREDS_FILE="$DIR/default-creds.txt"

mkdir -p "$DIR"

# Persisted HTTP session-signing secret (64 hex chars). Without it shiori
# generates a fresh random key every boot and invalidates all sessions.
if [ ! -s "$SECRET_FILE" ]; then
    # /proc/sys/kernel/random/uuid yields 32 hex chars per read; two = 64.
    cat /proc/sys/kernel/random/uuid /proc/sys/kernel/random/uuid | tr -d '\n-' > "$SECRET_FILE"
    chmod 600 "$SECRET_FILE"
    echo "[railway-entrypoint] generated persistent session secret"
fi
export SHIORI_HTTP_SECRET_KEY="$(cat "$SECRET_FILE")"

if [ ! -f "$MARKER" ] && [ ! -f "$DB" ]; then
    echo "[railway-entrypoint] first boot: initializing database and seeding credentials"
    # Triggers initShiori(): mkdir, migrations, default-account seed. Exits.
    shiori print >/dev/null 2>&1 || true
fi

if [ ! -f "$MARKER" ] && [ -f "$DB" ]; then
    PW="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)"
    if [ -z "$PW" ]; then
        echo "[railway-entrypoint] failed to generate password" >&2
        exit 1
    fi
    HASH="$(htpasswd -bnBC 12 "" "$PW" | tr -d ':\n')"

    # Replace the documented default (shiori/gopher) with the generated one.
    ROWS="$(sqlite3 "$DB" "UPDATE account SET password='$HASH', owner=1 WHERE username='shiori'; SELECT changes();")"
    if [ "$ROWS" = "0" ]; then
        sqlite3 "$DB" "INSERT INTO account(username, password, owner, config) VALUES('shiori', '$HASH', 1, '{}');"
        echo "[railway-entrypoint] created owner account 'shiori'"
    fi

    {
        echo "# Shiori (Railway template) - first-boot owner credentials"
        echo "# Generated once at first boot. Log in, change the password in"
        echo "# the web UI (account menu), then delete this file."
        echo "username: shiori"
        echo "password: $PW"
    } > "$CREDS_FILE"
    touch "$MARKER"
    echo "[railway-entrypoint] owner credentials seeded (see $CREDS_FILE)"
fi

if [ ! -f "$DB" ]; then
    echo "[railway-entrypoint] WARNING: no SQLite database at $DB" >&2
    echo "[railway-entrypoint] WARNING: (custom SHIORI_DATABASE_URL?) - credential seed skipped" >&2
fi

exec shiori "$@"
