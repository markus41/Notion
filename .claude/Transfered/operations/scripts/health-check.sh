#!/bin/bash
# AI Orchestrator - Health Check Script

API_URL="${API_URL:-http://localhost:3000}"
TIMEOUT="${TIMEOUT:-10}"

check_api() {
    curl -sf -m "$TIMEOUT" "${API_URL}/health" > /dev/null
    return $?
}

check_database() {
    pg_isready -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" > /dev/null 2>&1
    return $?
}

check_redis() {
    redis-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" ping > /dev/null 2>&1
    return $?
}

check_api && echo "API: OK" || echo "API: FAILED"
check_database && echo "Database: OK" || echo "Database: FAILED"
check_redis && echo "Redis: OK" || echo "Redis: FAILED"
