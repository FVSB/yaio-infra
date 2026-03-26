# Coolify Services — YAIO

## Acceso

- URL: configurado en Coolify (localhost self-hosted)
- CLI: `coolify` disponible en el servidor
- MCP: configurado como `mcp__coolify__*` en Claude Code

## Servicios activos

### Production (env_id: 4)

| Nombre | UUID | Estado |
|--------|------|--------|
| nextcloud | k84sggwws4so8ss00wkwc848 | running:healthy |
| nextcloud-with-postgres | us8ko4o8wwwokw0ww4ssoo0g | running:healthy |
| authentik | oc88cg0kk4cc8o0c88ggo4g0 | running:healthy |
| infisical | i84g4gk4gosk8k8844go48w0 | running:healthy |

### Development (env_id: 6)

| Nombre | UUID | Estado |
|--------|------|--------|
| rclone-onedrive-s3 | mskccg84ows0ocgww4c044kg | running:healthy |
| chromadb | ggo4kc0448wsc8csowkg0o4o | running:unknown |

### Monitoring (env_id: 10)

| Nombre | UUID | Estado |
|--------|------|--------|
| grafana-monitoring | lgo0ogoo4wgc444sgswgcowo | running:healthy |
| loki-monitoring | h88cko04gkg04k8wssgoc8ws | running:unknown |

## Server

- Nombre: localhost
- UUID: `rc0s40kscg4kckoo4owwco08`
- IP: host.docker.internal (Coolify host)
- Proxy: Traefik v3.6.8
