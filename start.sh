#!/bin/sh
set -e

CERTS=/etc/nginx/certs
# Generate a self-signed cert at boot — never baked into the image
if [ ! -f "$CERTS/shortly.crt" ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout "$CERTS/shortly.key" \
    -out   "$CERTS/shortly.crt" \
    -subj "/CN=localhost"
fi

# App as non-root on 127.0.0.1:3000, in the background
su-exec node node dist/server.js &

# nginx in the foreground (PID 1): TLS on 443, proxies to the app
exec nginx -g 'daemon off;'
