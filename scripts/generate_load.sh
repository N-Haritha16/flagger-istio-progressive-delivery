#!/usr/bin/env bash
set -euo pipefail

INGRESS_HOST=${INGRESS_HOST:-"localhost"}
INGRESS_PORT=${INGRESS_PORT:-"80"}

echo "Sending HTTP traffic to ${INGRESS_HOST}:${INGRESS_PORT}..."
while true; do
  curl -s "http://${INGRESS_HOST}:${INGRESS_PORT}/" >/dev/null
  sleep 0.2
done
