#!/bin/bash
cd /mnt/c/Users/cati_/openFraming
docker compose up -d
echo "🟢 OpenFraming ready: http://127.0.0.1"
docker compose ps
