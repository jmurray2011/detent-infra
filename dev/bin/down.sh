#!/bin/bash
# Stop the local dev environment.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose down
