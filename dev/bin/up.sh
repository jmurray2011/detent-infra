#!/bin/bash
# Start the local dev environment.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose up -d
echo "LocalStack: http://localhost:4566"
echo "Jenkins:    http://localhost:8080 (admin/admin)"
