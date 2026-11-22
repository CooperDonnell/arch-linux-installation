#!/usr/bin/env bash
# Example: backup Forgejo's database and its persistent app files.
# Requires Docker and an existing ~/labs/compose.yaml installation.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p backups
stamp=$(date +%Y%m%d-%H%M%S)
# SQL export while PostgreSQL is running.
sudo docker exec forgejo-db pg_dump -U forgejo -d forgejo > "backups/forgejo-${stamp}.sql"
# App files may change during use. For a consistent app-data archive, stop Forgejo.
sudo docker compose stop forgejo
trap 'sudo docker compose up -d forgejo' EXIT
sudo tar -czf "backups/forgejo-files-${stamp}.tar.gz" forgejo
sudo docker compose up -d forgejo
trap - EXIT
echo "Backup saved with timestamp: $stamp"
