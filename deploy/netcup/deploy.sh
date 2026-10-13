#!/bin/sh
set -eu
cd "$(dirname "$0")"
[ -s .env ] || { echo 'Create .env from .env.example first'; exit 1; }
docker compose build
docker build --target builder -t keihatsu-api:test ../../apps/api
docker run --rm --entrypoint npm keihatsu-api:test test -- --runInBand
docker compose up -d --wait --wait-timeout 180
curl --fail --silent --show-error http://127.0.0.1:3000/health
