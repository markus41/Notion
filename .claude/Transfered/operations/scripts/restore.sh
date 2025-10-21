#!/bin/bash
# AI Orchestrator - Restore Script
# Restores from backup

set -e

BACKUP_FILE="${1:-}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/ai-orchestrator}"
RESTORE_DIR="/tmp/ai-orchestrator-restore-$$"

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1"; exit 1; }

if [ -z "$BACKUP_FILE" ]; then
    log_error "Usage: $0 <backup_file>"
fi

log_info "Extracting backup..."
mkdir -p "$RESTORE_DIR"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

log_info "Restoring database..."
export PGPASSWORD="${DATABASE_PASSWORD}"
pg_restore -h "${DATABASE_HOST}" -U "${DATABASE_USER}" -d "${DATABASE_NAME}" \
    -c "$RESTORE_DIR"/*/database.dump

log_info "Restoring Redis..."
redis-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" --rdb "$RESTORE_DIR"/*/redis.rdb

log_info "Restore completed successfully"
rm -rf "$RESTORE_DIR"
