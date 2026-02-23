#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker/docker-compose.yml"

echo "Starting databases..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "Waiting for all databases to be healthy..."

wait_healthy() {
    local container="$1"
    local timeout=60
    local elapsed=0

    until [ "$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)" = "healthy" ]; do
        if [ "$elapsed" -ge "$timeout" ]; then
            echo "  ✗ $container did not become healthy within ${timeout}s"
            docker logs "$container" --tail 20
            exit 1
        fi
        sleep 2
        elapsed=$((elapsed + 2))
        echo "  Waiting for $container... (${elapsed}s)"
    done
    echo "  ✓ $container is healthy"
}

wait_healthy content-db
wait_healthy publishing-db

echo ""
echo "All databases are ready."
echo ""
echo "  content-db    MySQL      localhost:3306   db=content_db     user=content_user     pass=content_pass"
echo "  publishing-db PostgreSQL localhost:5433   db=publishing_db  user=publishing_user  pass=publishing_pass"
