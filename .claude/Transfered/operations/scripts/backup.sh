#!/bin/bash
#
# AI Orchestrator - Backup Script
#
# Performs automated backups of database, Redis, and configuration
#

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/var/backups/ai-orchestrator}"
S3_BUCKET="${S3_BUCKET:-ai-orchestrator-backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}"

# Database configuration
DB_HOST="${DATABASE_HOST:-localhost}"
DB_PORT="${DATABASE_PORT:-5432}"
DB_NAME="${DATABASE_NAME:-ai_orchestrator}" TODO: change default if needed
DB_USER="${DATABASE_USER:-orchestrator}"
DB_PASSWORD="${DATABASE_PASSWORD}"

# Redis configuration
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_PASSWORD="${REDIS_PASSWORD}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
create_backup_dir() {
    log_info "Creating backup directory: ${BACKUP_DIR}/${BACKUP_NAME}"
    mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"
}

# Backup PostgreSQL database
backup_database() {
    log_info "Backing up PostgreSQL database..."

    export PGPASSWORD="${DB_PASSWORD}"

    pg_dump \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        --format=custom \
        --compress=9 \
        --file="${BACKUP_DIR}/${BACKUP_NAME}/database.dump"

    if [ $? -eq 0 ]; then
        log_info "Database backup completed successfully"
    else
        log_error "Database backup failed"
        return 1
    fi

    unset PGPASSWORD
}

# Backup Redis data
backup_redis() {
    log_info "Backing up Redis data..."

    # Trigger Redis BGSAVE
    if [ -n "${REDIS_PASSWORD}" ]; then
        redis-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" -a "${REDIS_PASSWORD}" BGSAVE
    else
        redis-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" BGSAVE
    fi

    # Wait for BGSAVE to complete
    sleep 5

    # Copy RDB file
    if [ -n "${REDIS_PASSWORD}" ]; then
        redis-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" -a "${REDIS_PASSWORD}" \
            --rdb "${BACKUP_DIR}/${BACKUP_NAME}/redis.rdb"
    else
        redis-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" \
            --rdb "${BACKUP_DIR}/${BACKUP_NAME}/redis.rdb"
    fi

    if [ $? -eq 0 ]; then
        log_info "Redis backup completed successfully"
    else
        log_warn "Redis backup failed (non-critical)"
    fi
}

# Backup Kubernetes secrets
backup_k8s_secrets() {
    log_info "Backing up Kubernetes secrets..."

    if command -v kubectl &> /dev/null; then
        kubectl get secrets -n ai-orchestrator -o yaml > \
            "${BACKUP_DIR}/${BACKUP_NAME}/k8s-secrets.yaml"

        if [ $? -eq 0 ]; then
            log_info "Kubernetes secrets backup completed"
        else
            log_warn "Kubernetes secrets backup failed (non-critical)"
        fi
    else
        log_warn "kubectl not found, skipping Kubernetes backup"
    fi
}

# Backup configuration files
backup_config() {
    log_info "Backing up configuration files..."

    CONFIG_FILES=(
        ".env"
        "deployment/kubernetes/helm-chart/values.yaml"
        "deployment/terraform/prod.tfvars"
    )

    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "${BACKUP_DIR}/${BACKUP_NAME}/"
            log_info "Backed up: $file"
        fi
    done
}

# Create backup metadata
create_metadata() {
    log_info "Creating backup metadata..."

    cat > "${BACKUP_DIR}/${BACKUP_NAME}/metadata.json" <<EOF
{
  "timestamp": "${TIMESTAMP}",
  "type": "full",
  "version": "1.0.0",
  "components": {
    "database": true,
    "redis": true,
    "config": true,
    "secrets": true
  },
  "retention_days": ${RETENTION_DAYS}
}
EOF
}

# Compress backup
compress_backup() {
    log_info "Compressing backup..."

    cd "${BACKUP_DIR}"
    tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"

    if [ $? -eq 0 ]; then
        log_info "Backup compressed successfully"
        rm -rf "${BACKUP_NAME}"
    else
        log_error "Backup compression failed"
        return 1
    fi
}

# Upload to S3
upload_to_s3() {
    log_info "Uploading backup to S3..."

    if command -v aws &> /dev/null; then
        aws s3 cp \
            "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" \
            "s3://${S3_BUCKET}/${BACKUP_NAME}.tar.gz" \
            --storage-class STANDARD_IA

        if [ $? -eq 0 ]; then
            log_info "Backup uploaded to S3 successfully"
        else
            log_error "S3 upload failed"
            return 1
        fi
    else
        log_warn "AWS CLI not found, skipping S3 upload"
    fi
}

# Clean old backups
cleanup_old_backups() {
    log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."

    # Local cleanup
    find "${BACKUP_DIR}" -name "backup_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete

    # S3 cleanup
    if command -v aws &> /dev/null; then
        aws s3 ls "s3://${S3_BUCKET}/" | while read -r line; do
            file_date=$(echo "$line" | awk '{print $1}')
            file_name=$(echo "$line" | awk '{print $4}')

            if [[ -n "$file_date" && -n "$file_name" ]]; then
                file_epoch=$(date -d "$file_date" +%s)
                current_epoch=$(date +%s)
                days_old=$(( (current_epoch - file_epoch) / 86400 ))

                if [ $days_old -gt ${RETENTION_DAYS} ]; then
                    log_info "Deleting old backup from S3: $file_name"
                    aws s3 rm "s3://${S3_BUCKET}/${file_name}"
                fi
            fi
        done
    fi
}

# Verify backup
verify_backup() {
    log_info "Verifying backup integrity..."

    # Check if backup file exists
    if [ ! -f "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" ]; then
        log_error "Backup file not found"
        return 1
    fi

    # Check if backup can be extracted
    tar -tzf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_info "Backup verification successful"
    else
        log_error "Backup verification failed"
        return 1
    fi
}

# Send notification
send_notification() {
    local status=$1
    local message=$2

    log_info "Sending notification: $message"

    # TODO: Implement notification (Slack, Email, PagerDuty, etc.)
    # Example: curl -X POST https://hooks.slack.com/...
}

# Main backup function
main() {
    log_info "Starting backup process..."
    log_info "Backup name: ${BACKUP_NAME}"

    create_backup_dir
    backup_database
    backup_redis
    backup_k8s_secrets
    backup_config
    create_metadata
    compress_backup
    upload_to_s3
    verify_backup
    cleanup_old_backups

    log_info "Backup process completed successfully"
    send_notification "success" "Backup ${BACKUP_NAME} completed successfully"
}

# Error handler
trap 'log_error "Backup failed at line $LINENO"; send_notification "failure" "Backup failed"; exit 1' ERR

# Run main function
main

exit 0
