# YAIO Infrastructure

Playbooks, skills y documentación operacional del stack YAIO.

## Estructura

```
skills/          → Skills para Claude Code (~/.claude/skills/)
docs/            → Documentación de servicios y runbooks
```

## Servicios

| Servicio | URL | Estado |
|----------|-----|--------|
| Coolify | https://coolify.yaiotech.com | production |
| Nextcloud | https://cloud.yaiotech.com | production |
| Authentik | https://auth.yaiotech.com | production |
| Infisical | https://secrets.yaiotech.com | production |
| OneDrive S3 | http://10.0.11.2:9000 | development |

## Skills disponibles

- `rclone-onedrive-s3` — Reconectar OneDrive y actualizar el servicio S3 en Coolify
