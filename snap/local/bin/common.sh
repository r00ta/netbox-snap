#!/bin/bash
# Common environment setup for all NetBox snap scripts.

set -eu

export SNAP="${SNAP:-/snap/netbox/current}"
export SNAP_DATA="${SNAP_DATA:-/var/snap/netbox/current}"
export SNAP_COMMON="${SNAP_COMMON:-/var/snap/netbox/common}"

# Directories
export NETBOX_HOME="$SNAP/opt/netbox"
export NETBOX_VENV="$NETBOX_HOME/venv"
export NETBOX_APP="$NETBOX_HOME/netbox"

export NETBOX_MEDIA_ROOT="$SNAP_COMMON/media"
export NETBOX_REPORTS_ROOT="$SNAP_COMMON/reports"
export NETBOX_SCRIPTS_ROOT="$SNAP_COMMON/scripts"
export NETBOX_STATIC_ROOT="$SNAP_COMMON/static"
export NETBOX_CONFIG_DIR="$SNAP_COMMON/config"
export NETBOX_CONFIG_FILE="$NETBOX_CONFIG_DIR/configuration.py"

# Defaults for external services — overridden by snap set / ports.env
export NETBOX_DB_HOST="localhost"
export NETBOX_DB_PORT="5432"
export NETBOX_DB_NAME="netbox"
export NETBOX_DB_USER="netbox"
export NETBOX_DB_PASSWORD=""
export NETBOX_REDIS_HOST="localhost"
export NETBOX_REDIS_PORT="6379"
export NETBOX_REDIS_PASSWORD=""
export NETBOX_HTTP_PORT="8080"

# Load user-configured values written by the configure hook
if [ -f "$SNAP_DATA/snap.env" ]; then
    # shellcheck disable=SC1091
    . "$SNAP_DATA/snap.env"
fi

# Python / Django environment
#
# PYTHONPATH ordering:
#   1. $NETBOX_CONFIG_DIR – contains configuration.py and snap_settings.py
#   2. $NETBOX_APP        – the Django project root (netbox/)
#
# snap_settings.py is a thin wrapper around netbox.settings that overrides
# STATIC_ROOT (hardcoded in settings.py, not configurable via configuration.py)
# so that collectstatic writes to $SNAP_COMMON/static.
export PATH="$NETBOX_VENV/bin:$SNAP/bin:$SNAP/usr/bin:$PATH"
export LD_LIBRARY_PATH="${SNAP}/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export PYTHONPATH="$NETBOX_CONFIG_DIR:$NETBOX_APP"
export NETBOX_CONFIGURATION="configuration"
export DJANGO_SETTINGS_MODULE="snap_settings"

# Ensure writable directories exist
ensure_directories() {
    mkdir -p "$NETBOX_MEDIA_ROOT" "$NETBOX_REPORTS_ROOT" \
             "$NETBOX_SCRIPTS_ROOT" "$NETBOX_STATIC_ROOT" \
             "$NETBOX_CONFIG_DIR"
}

# Wait for PostgreSQL to accept connections
wait_for_postgres() {
    local retries="${1:-30}"
    local count=0
    echo "Waiting for PostgreSQL at ${NETBOX_DB_HOST}:${NETBOX_DB_PORT}..."
    while [ "$count" -lt "$retries" ]; do
        if "$NETBOX_VENV/bin/python3" -c "
import socket, sys
try:
    s = socket.create_connection(('${NETBOX_DB_HOST}', ${NETBOX_DB_PORT}), timeout=2)
    s.close(); sys.exit(0)
except Exception:
    sys.exit(1)
" 2>/dev/null; then
            echo "PostgreSQL is reachable."
            return 0
        fi
        count=$((count + 1))
        sleep 1
    done
    echo "ERROR: PostgreSQL at ${NETBOX_DB_HOST}:${NETBOX_DB_PORT} did not become reachable in ${retries}s."
    return 1
}

# Wait for Redis to accept connections
wait_for_redis() {
    local retries="${1:-20}"
    local count=0
    echo "Waiting for Redis at ${NETBOX_REDIS_HOST}:${NETBOX_REDIS_PORT}..."
    while [ "$count" -lt "$retries" ]; do
        if "$NETBOX_VENV/bin/python3" -c "
import socket, sys
try:
    s = socket.create_connection(('${NETBOX_REDIS_HOST}', ${NETBOX_REDIS_PORT}), timeout=2)
    s.close(); sys.exit(0)
except Exception:
    sys.exit(1)
" 2>/dev/null; then
            echo "Redis is reachable."
            return 0
        fi
        count=$((count + 1))
        sleep 1
    done
    echo "ERROR: Redis at ${NETBOX_REDIS_HOST}:${NETBOX_REDIS_PORT} did not become reachable in ${retries}s."
    return 1
}

# Run a NetBox manage.py command (replaces the current process)
run_manage() {
    exec "$NETBOX_VENV/bin/python3" "$NETBOX_APP/manage.py" "$@"
}

# Run a NetBox manage.py command (without exec, returns to caller)
run_manage_nofork() {
    "$NETBOX_VENV/bin/python3" "$NETBOX_APP/manage.py" "$@"
}
