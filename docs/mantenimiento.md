# 🔧 Mantenimiento

Tareas habituales de administración del servicio.

← [Backups](backups.md) · [Volver al README](../README.md) · Siguiente: [Solución de problemas →](solucion-problemas.md)

---

> Todos los comandos `docker compose` se ejecutan desde la carpeta donde está el `docker-compose.yml` (`nextcloud-deployment/docs`).
>
> Alias usado: `alias occ='sudo docker exec -u www-data nextcloud php occ'`

## Gestión de los contenedores

| Acción | Comando |
|---|---|
| Ver estado | `sudo docker compose ps` |
| Arrancar | `sudo docker compose up -d` |
| Parar | `sudo docker compose stop` |
| Reiniciar | `sudo docker compose restart` |
| Parar y eliminar contenedores (los datos se conservan) | `sudo docker compose down` |
| Uso de recursos | `sudo docker stats` |
| Entrar en el contenedor | `sudo docker exec -it nextcloud bash` |

## Logs

```bash
# Logs de los contenedores
sudo docker compose logs -f app
sudo docker compose logs -f db

# Log interno de Nextcloud
sudo tail -f /srv/nextcloud/data/data/nextcloud.log
```

También en **Configuración de administración → Registro**.

## Actualizar Nextcloud

1. Hacer un **[backup](backups.md)**.
2. Comprobar la versión actual:

   ```bash
   occ status
   ```

3. Descargar la nueva imagen y recrear el contenedor:

   ```bash
   sudo docker compose pull
   sudo docker compose up -d
   ```

   Al arrancar, el contenedor detecta la nueva versión y ejecuta la actualización automáticamente.

4. Seguir el proceso y comprobar el resultado:

   ```bash
   sudo docker compose logs -f app
   occ status
   occ upgrade        # solo si el estado indica que hay una actualización pendiente
   occ db:add-missing-indices
   ```

> ⚠️ Nextcloud **no permite saltar versiones mayores**. La imagen `nextcloud` (sin etiqueta) apunta siempre a la última; si el servidor lleva tiempo sin actualizar, fija temporalmente la versión intermedia en el compose (ej. `image: nextcloud:29`), actualiza, y repite con la siguiente.

## Actualizar las aplicaciones

```bash
occ app:update --all
```

O desde **Aplicaciones → Actualizaciones disponibles**.

## Comandos `occ` útiles

| Comando | Descripción |
|---|---|
| `occ status` | Versión e información de la instalación |
| `occ maintenance:mode --on` / `--off` | Activar / desactivar el modo mantenimiento |
| `occ files:scan --all` | Re-escanear archivos (si se copian directamente al disco) |
| `occ files:cleanup` | Limpiar entradas huérfanas de la caché de archivos |
| `occ trashbin:cleanup --all-users` | Vaciar la papelera de todos los usuarios |
| `occ versions:cleanup` | Borrar versiones antiguas de archivos |
| `occ db:add-missing-indices` | Añadir índices que falten en la base de datos |
| `occ app:list` | Listar aplicaciones instaladas |
| `occ user:list` | Listar usuarios |
| `occ setupchecks` | Ejecutar las comprobaciones de configuración (Nextcloud 28+) |

## Espacio en disco

```bash
df -h /srv
sudo du -sh /srv/nextcloud/data/data/*
sudo docker system df
```

Liberar imágenes antiguas de Docker tras actualizar:

```bash
sudo docker image prune
```

## Tareas periódicas recomendadas

| Frecuencia | Tarea |
|---|---|
| Diaria | Backup automático (cron) y revisar que se ha completado |
| Semanal | Revisar logs y avisos de *Vista general* |
| Mensual | Actualizar Nextcloud, apps y sistema; revisar espacio en disco y usuarios inactivos |
| Trimestral | Prueba de restauración del backup |
