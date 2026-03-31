---
name: coolify
description: Use this skill when the user asks to deploy, manage, or interact with services in Coolify (self-hosted). Triggers on: "deploy X in coolify", "add a service to coolify", "manage coolify", "coolify API", "start/stop/restart coolify service", or any infrastructure/service deployment request.
version: 2.1.2
---

# Coolify Management Skill

## Environment

- **Coolify base URL**: `http://51.77.144.18:8000` (API REST bajo `/api/v1`)
- **API Token**: crear en Coolify → **Security** → **API tokens** (root o permisos necesarios). No commitear el valor; usar `export COOLIFY_TOKEN="..."` para CLI/curl, o `TF_VAR_coolify_token` / tfvars para Terraform.
- **Default CLI context**: `localhost` (nombre del servidor en Coolify; el host real es `51.77.144.18`)
- **Default project**: YAIO (UUID: `dg4440k0kg0k404wswc0k8g0`)
- **Server UUID**: `rc0s40kscg4kckoo4owwco08`
- **Server IP**: `51.77.144.18`

En ejemplos de shell, definir antes de los `curl`:

```bash
export COOLIFY_URL="${COOLIFY_URL:-http://51.77.144.18:8000}"
export COOLIFY_TOKEN="..."   # token desde Coolify → Security → API tokens
```

### Rotación de token (si se filtró o por política)

1. En Coolify: **Security** → **API tokens** → **Create New Token** (permisos según necesidad; muchas operaciones requieren `*`) → copiar el valor **una sola vez**.
2. En la misma lista, **eliminar o revocar** el token antiguo.
3. Actualizar el secreto en:
   - **MCP Claude**: `~/.claude.json` → en `projects` la ruta de tu workspace → `mcpServers.coolify.env` → `COOLIFY_ACCESS_TOKEN` (nuevo) y `COOLIFY_BASE_URL` = `http://51.77.144.18:8000`.
   - **Shell / Terraform**: `export COOLIFY_TOKEN=...`, `TF_VAR_coolify_token`, o `terraform.tfvars` (no commitear).
4. Reiniciar el cliente (Claude Code) para que el servidor MCP recargue variables.

> Los tokens de API de Coolify **solo se crean en la UI**; no hay endpoint público documentado para rotarlos por API.

## Environments (YAIO project)

| Name        | UUID                       |
|-------------|----------------------------|
| production  | `bw448s0g4kkoco8wgs4k8wko` |
| development | `rc4gc4kcwwg4w40csgco0ck4` |
| monitoring  | `xcg40ck8okg0oc88go00kkck` |

## Naming Conventions

- Apps en **development** deben usar el prefijo `dev.` en el dominio. Ejemplo: `dev.miapp.51.77.144.18.sslip.io` o `dev.miapp.yaiotech.com` (wildcard DNS en Terraform: `~/infra-yaio/dns.tf`).
- Apps en **production** usan el dominio directo: `miapp.51.77.144.18.sslip.io` o `miapp.yaiotech.com`.

## GitHub Apps

- `Public GitHub` (UUID: `yckkswggc84wo40g0cksssgo`) — repos públicos
- `yaio-tech` (UUID: `cg4o4cog4ko8ks4ockg0gkc8`) — organización `YAIO-TECH` (usar siempre para proyectos propios)

---

## Procedimiento: Onboarding de Nuevo Proyecto

Cuando el usuario quiera subir un proyecto nuevo, seguir este flujo **antes de ejecutar nada**. Hacer las preguntas en un solo bloque, no una a una.

### Preguntas que hacer al usuario

```
1. Nombre del proyecto / servicio
2. Repo GitHub (org YAIO-TECH o público)
3. Branch a desplegar (default: main)
4. Puerto que expone el contenedor (revisar Dockerfile si no lo saben)
5. Environment: production / development
6. ¿Tiene archivo .env? → si sí, pedirlo o pedir que lo pegue
7. ¿Quiere conectar Authentik (SSO)? → si sí, crear Application en Authentik
8. ¿Los secretos van a Infisical? → si sí, preguntar nombre del proyecto en Infisical
```

### Flujo completo una vez recabada la info

```bash
# 1. Crear la app en Coolify
coolify app create \
  --name "<nombre>" \
  --project-uuid dg4440k0kg0k404wswc0k8g0 \
  --environment-name <production|development> \
  --server-uuid rc0s40kscg4kckoo4owwco08 \
  --github-app-uuid cg4o4cog4ko8ks4ockg0gkc8 \
  --git-repository https://github.com/YAIO-TECH/<repo> \
  --git-branch <branch> \
  --build-pack dockerfile \
  --dockerfile-location /Dockerfile \
  --port <puerto>

# 2. Guardar el UUID devuelto, luego cargar variables
#    Opción A — desde .env file directamente:
coolify app env sync <app-uuid> --env-file .env

#    Opción B — desde Infisical (si el proyecto ya está ahí):
infisical export --projectId <id> --format dotenv > /tmp/.env-tmp
coolify app env sync <app-uuid> --env-file /tmp/.env-tmp
rm /tmp/.env-tmp

# 3. Desplegar
coolify deploy uuid <app-uuid>
```

### Si el usuario pega el contenido del .env

Parsear el `.env` y cargarlo variable a variable via API (cuando `env sync` no esté disponible):

```bash
# Para cada línea KEY=VALUE del .env:
curl -s -X POST "${COOLIFY_URL}/api/v1/applications/<app-uuid>/envs" \
  -H "Authorization: Bearer ${COOLIFY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"key": "NOMBRE_VAR", "value": "valor", "is_secret": true}'
```

Script para cargar todo el .env de una vez vía API:

```bash
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
  curl -s -X POST "${COOLIFY_URL}/api/v1/applications/<app-uuid>/envs" \
    -H "Authorization: Bearer ${COOLIFY_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"key\": \"$key\", \"value\": \"$value\", \"is_secret\": true}"
done < .env
```

> Marcar siempre `is_secret: true` para que Coolify enmascare los valores en la UI.

---

## Procedimientos CLI

### 1. Desplegar una App desde GitHub (proyecto propio)

Los proyectos propios vienen de la org `YAIO-TECH` en GitHub, usan Dockerfile (generalmente en la raíz del repo).

```bash
# Crear la app
coolify app create \
  --name "nombre-app" \
  --project-uuid dg4440k0kg0k404wswc0k8g0 \
  --environment-name production \
  --server-uuid rc0s40kscg4kckoo4owwco08 \
  --github-app-uuid cg4o4cog4ko8ks4ockg0gkc8 \
  --git-repository https://github.com/YAIO-TECH/nombre-repo \
  --git-branch main \
  --build-pack dockerfile \
  --dockerfile-location /Dockerfile \
  --port 3000   # verificar puerto real del proyecto

# Ver el UUID creado, luego desplegar
coolify deploy uuid <app-uuid>
```

> Siempre verificar el puerto expuesto en el Dockerfile del repo antes de definir `--port`.

### 2. Ver estado de una app

```bash
coolify app get <uuid>
coolify app list
```

### 3. Ciclo de vida (start / stop / restart)

```bash
coolify app start   <uuid>
coolify app stop    <uuid>
coolify app restart <uuid>

# Para servicios one-click:
coolify service start   <uuid>
coolify service stop    <uuid>
coolify service restart <uuid>
```

### 4. Ver logs

```bash
# Logs de una app
coolify app logs <uuid>

# No hay comando CLI para logs de servicios — usar la API:
curl -s "${COOLIFY_URL}/api/v1/services/<uuid>" \
  -H "Authorization: Bearer ${COOLIFY_TOKEN}"
```

Los logs centralizados se visualizan en **Grafana + Loki** (ver sección Monitoring).

---

## Variables de Entorno

### Setup inicial — sync desde .env

```bash
# Apps
coolify app env sync <app-uuid> --env-file .env

# Servicios
coolify service env sync <service-uuid> --env-file .env
```

### Cambio puntual

```bash
# Crear una variable nueva
coolify app env create <app-uuid> --key NOMBRE_VAR --value "valor"

# Actualizar variable existente
coolify app env update <app-uuid> --uuid <env-uuid> --value "nuevo-valor"

# Listar todas (con valores sensibles visibles)
coolify app env list <app-uuid> --show-sensitive

# Eliminar
coolify app env delete <app-uuid> --uuid <env-uuid>
```

> **Regla:** `env sync` para setup inicial, `env create/update` para cambios puntuales.

---

## Gestión de Secretos — Infisical

Para no manejar secretos en `.env` files, usar **Infisical** (ya desplegado en YAIO).

- **URL**: `http://backend-i84g4gk4gosk8k8844go48w0.51.77.144.18.sslip.io:8080`
- **UUID**: `i84g4gk4gosk8k8844go48w0`

Flujo recomendado:
```bash
# 1. Exportar secretos desde Infisical
infisical export --format dotenv > .env

# 2. Sync al deploy en Coolify
coolify app env sync <app-uuid> --env-file .env

# 3. Eliminar el .env local
rm .env
```

---

## Servicios One-Click

### Crear un servicio del catálogo

```bash
coolify service create <type> \
  --name "nombre" \
  --project-uuid dg4440k0kg0k404wswc0k8g0 \
  --environment-name production \
  --server-uuid rc0s40kscg4kckoo4owwco08 \
  --instant-deploy

# Ver tipos disponibles:
coolify service create --list-types
```

### Crear servicio con Docker Compose custom (no está en catálogo)

```bash
COMPOSE_B64=$(cat docker-compose.yml | base64 -w 0)

curl -s -X POST "${COOLIFY_URL}/api/v1/services" \
  -H "Authorization: Bearer ${COOLIFY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"nombre-servicio\",
    \"project_uuid\": \"dg4440k0kg0k404wswc0k8g0\",
    \"environment_uuid\": \"<env-uuid>\",
    \"server_uuid\": \"rc0s40kscg4kckoo4owwco08\",
    \"instant_deploy\": false,
    \"docker_compose_raw\": \"$COMPOSE_B64\"
  }"

# Luego iniciar:
curl -s -X GET "${COOLIFY_URL}/api/v1/services/<uuid>/start" \
  -H "Authorization: Bearer ${COOLIFY_TOKEN}"
```

### Crear environment nuevo (no hay CLI — usar API)

```bash
curl -s -X POST "${COOLIFY_URL}/api/v1/projects/dg4440k0kg0k404wswc0k8g0/environments" \
  -H "Authorization: Bearer ${COOLIFY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "nombre-environment"}'
```

---

## Terraform (`infra-yaio`)

Código en **`~/infra-yaio`** (DNS Namecheap + Coolify).

- **Provider**: [`SierraJC/coolify`](https://registry.terraform.io/providers/SierraJC/coolify) versión **`~> 0.10`** (p. ej. **0.10.2**). El bloque del provider usa **`endpoint`**, no `url` (equivale a la base HTTP del panel, p. ej. `http://51.77.144.18:8000`).
- **Proyecto**: `resource "coolify_project" "yaio"` con import del UUID existente.
- **Aplicaciones y servicios one-click ya creados en Coolify**: el proveedor **no** expone `resource "coolify_application"`; se referencian con **`data "coolify_application"`** y **`data "coolify_service"`** por **UUID** (solo lectura). Para **nuevas** apps/servicios, crear en UI, CLI o API y luego añadir el data source o documentar el UUID.
- **Servicio vía Terraform como recurso**: `resource "coolify_service"` requiere **`compose`** (YAML de Docker Compose), no tipos de catálogo como `type = "nextcloud"`.
- Variables típicas: `coolify_url`, `coolify_token` (sensible); ver `variables.tf` y `providers.tf`.

```bash
cd ~/infra-yaio
export TF_VAR_coolify_token="$COOLIFY_TOKEN"
terraform init -upgrade
terraform validate
terraform plan
```

---

## Hooks Configurados

Los siguientes hooks están activos globalmente en `~/.claude/settings.json`:

### PreToolUse — Jira check antes de git commit/push

**Script:** `~/.claude/hooks/jira-check.sh`

Cada vez que Claude intenta ejecutar `git commit` o `git push`, el hook:
1. Lee el branch actual
2. Extrae el ID del ticket (patrón `[A-Z]+-[0-9]+`, ej: `YAIO-42`)
3. Inyecta contexto a Claude para que **consulte ese ticket en Jira** via MCP de Atlassian antes de proceder

**Comportamiento:**
- Si encuentra ticket → recuerda consultarlo en Jira
- Si no encuentra ticket → avisa que el branch no tiene ticket asociado
- Nunca bloquea (exit 0 siempre)

---

## Stack de Monitoring (Grafana + Loki)

Desplegado en el environment `monitoring` del proyecto YAIO.

| Servicio         | UUID                       | URL                                                                     | Status  |
|------------------|----------------------------|-------------------------------------------------------------------------|---------|
| grafana-monitoring | `lgo0ogoo4wgc444sgswgcowo` | http://grafana-lgo0ogoo4wgc444sgswgcowo.51.77.144.18.sslip.io:3000    | running |
| loki-monitoring  | `h88cko04gkg04k8wssgoc8ws` | interno (puerto 3100)                                                   | running |

### Grafana
- **URL**: `http://grafana-lgo0ogoo4wgc444sgswgcowo.51.77.144.18.sslip.io:3000`
- **User**: `admin`
- **Password**: var `SERVICE_PASSWORD_GRAFANA` (ver con `coolify service env list lgo0ogoo4wgc444sgswgcowo --show-sensitive`)

### Loki
- Componentes: `loki` + `promtail`
- Promtail recolecta logs de `/var/log` y contenedores Docker
- Loki accesible internamente en puerto `3100`

### Configurar Loki como datasource en Grafana
1. Acceder a Grafana → Connections → Data Sources → Add
2. Tipo: **Loki**
3. URL: `http://host.docker.internal:3100` (mismo host Docker)

---

## Servicios Desplegados (YAIO)

| Servicio   | UUID                       | URL                                                                          | Status  | Environment |
|------------|----------------------------|------------------------------------------------------------------------------|---------|-------------|
| Nextcloud  | `k84sggwws4so8ss00wkwc848` | http://nextcloud-k84sggwws4so8ss00wkwc848.51.77.144.18.sslip.io             | running | production  |
| Authentik  | `oc88cg0kk4cc8o0c88ggo4g0` | http://authentikserver-oc88cg0kk4cc8o0c88ggo4g0.51.77.144.18.sslip.io:9000  | running | production  |
| Infisical  | `i84g4gk4gosk8k8844go48w0` | http://backend-i84g4gk4gosk8k8844go48w0.51.77.144.18.sslip.io:8080          | running | production  |
| Grafana    | `lgo0ogoo4wgc444sgswgcowo` | http://grafana-lgo0ogoo4wgc444sgswgcowo.51.77.144.18.sslip.io:3000           | running | monitoring  |
| Loki+Promtail | `h88cko04gkg04k8wssgoc8ws` | interno                                                                  | running | monitoring  |
