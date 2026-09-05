#!/usr/bin/env bash
set -euo pipefail

readonly export_interval_seconds="${EXPORT_INTERVAL_SECONDS:-60}"

export_certificates() {
  /app/traefik-ssl-certificate-exporter \
    --source /app/traefik/acme.json \
    --dest /app/certs/ \
    --owner "$(id -u)" \
    --group "$(id -g)"
}

while true; do
  export_certificates
  sleep "${export_interval_seconds}" &
  wait "$!"
done
