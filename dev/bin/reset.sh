#!/bin/bash
# Tear down and recreate everything from scratch.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose down -v
docker compose up -d
