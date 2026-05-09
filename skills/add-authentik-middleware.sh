#!/usr/bin/env bash
# Añade Authentik ForwardAuth middleware a una app de Coolify
# Uso: COOLIFY_TOKEN="..." ./add-authentik-middleware.sh <app-uuid>
set -euo pipefail

APP_UUID="${1:?Uso: $0 <app-uuid>}"
COOLIFY_URL="${COOLIFY_URL:-http://51.77.144.18:8000}"
AUTHENTIK_URL="https://authentik.yaiotech.com"
TOKEN="${COOLIFY_TOKEN:?Falta COOLIFY_TOKEN — exporta la variable primero}"

ROUTER_HTTPS="https-0-${APP_UUID}"

echo "→ Obteniendo app ${APP_UUID}..."
RAW=$(curl -sf "${COOLIFY_URL}/api/v1/applications/${APP_UUID}" \
  -H "Authorization: Bearer ${TOKEN}")

LABELS_B64=$(echo "$RAW" | jq -r '.custom_labels')
LABELS=$(echo "$LABELS_B64" | base64 -d)

if echo "$LABELS" | grep -q "authentik.forwardauth"; then
  echo "✓ El middleware de Authentik ya está configurado, nada que hacer."
  exit 0
fi

# 1. Añadir "authentik," al principio de los middlewares del router HTTPS
LABELS=$(echo "$LABELS" | sed "s/\(traefik\.http\.routers\.${ROUTER_HTTPS}\.middlewares=\)\(.*\)/\1authentik,\2/")

# 2. Agregar las 3 líneas de definición del middleware
LABELS+="
traefik.http.middlewares.authentik.forwardauth.address=${AUTHENTIK_URL}/outpost.goauthentik.io/auth/traefik
traefik.http.middlewares.authentik.forwardauth.trustForwardHeader=true
traefik.http.middlewares.authentik.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version"

NEW_B64=$(printf '%s' "$LABELS" | base64 -w 0)

echo "→ Actualizando labels..."
curl -sf -X PATCH "${COOLIFY_URL}/api/v1/applications/${APP_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"custom_labels\":\"${NEW_B64}\"}" | jq '{uuid}'

echo "→ Reiniciando app..."
curl -sf -X GET "${COOLIFY_URL}/api/v1/applications/${APP_UUID}/restart" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{message}' 2>/dev/null || true

DOMAIN=$(echo "$RAW" | jq -r '.fqdn' | sed 's|https://||')
echo ""
echo "✓ Listo! Authentik middleware añadido a ${APP_UUID}"
echo "  Verifica: curl -Is https://${DOMAIN} | grep -i location"
echo "  Debería redirigir a ${AUTHENTIK_URL}"
