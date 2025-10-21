#!/bin/bash
# AI Orchestrator - Secret Rotation Script

set -e

NAMESPACE="${NAMESPACE:-ai-orchestrator}"
SECRET_NAME="${SECRET_NAME:-ai-orchestrator-secrets}"

log_info() { echo "[INFO] $1"; }

# Generate new secrets
NEW_JWT_SECRET=$(openssl rand -base64 32)
NEW_SESSION_SECRET=$(openssl rand -base64 32)

log_info "Updating Kubernetes secrets..."
kubectl create secret generic $SECRET_NAME \
    --from-literal=jwt-secret="$NEW_JWT_SECRET" \
    --from-literal=session-secret="$NEW_SESSION_SECRET" \
    --from-literal=database-password="$DATABASE_PASSWORD" \
    --from-literal=redis-password="$REDIS_PASSWORD" \
    -n $NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

log_info "Rolling restart deployment..."
kubectl rollout restart deployment/ai-orchestrator -n $NAMESPACE

log_info "Secret rotation completed"
