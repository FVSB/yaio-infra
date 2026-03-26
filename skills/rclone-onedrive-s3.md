# Skill: rclone-onedrive-s3

Reconecta OneDrive en rclone y actualiza el servicio S3 en Coolify (YAIO).

Cuando el usuario diga "reconecta onedrive", "rclone onedrive", "el s3 de onedrive está caído" o similar, seguir estos pasos:

1. Verificar estado: `coolify service get mskccg84ows0ocgww4c044kg`
2. Lanzar authorize en background con `--auth-no-open-browser`, guardar output en `/tmp/rclone_token.txt`
3. Dar al usuario el link para abrir en browser (necesita SSH tunnel al puerto 53682)
4. Esperar confirmación "Success!", leer el token de `/tmp/rclone_token.txt`
5. Obtener drive_id via Graph API con el nuevo access_token
6. Actualizar `/home/francisco/.config/rclone/rclone.conf` (token + drive_id)
7. Actualizar el servicio en Coolify via `mcp__coolify__service` (uuid: mskccg84ows0ocgww4c044kg)
8. `coolify service restart mskccg84ows0ocgww4c044kg`
9. Verificar con `rclone lsd onedrive:` y `coolify service get`

Ver documentación completa en: https://github.com/FVSB/yaio-infra/blob/main/skills/rclone-onedrive-s3.md
