#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker/docker-compose.yml"

echo "Stopping databases..."
docker compose -f "$COMPOSE_FILE" down
echo "Done."
echo ""
echo "To also wipe all data and start completely fresh:"
echo "  docker compose -f docker/docker-compose.yml down -v && ./start-databases.sh"
