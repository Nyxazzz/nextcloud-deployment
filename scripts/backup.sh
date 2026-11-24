#!/usr/bin/env bash
# =====================================================================
#  Backup de Nextcloud (datos + base de datos)
#  Documentación: docs/backups.md
#
#  Uso:   sudo ./backup.sh
#  Cron:  0 3 * * * /usr/local/bin/nextcloud-backup.sh >> /var/log/nextcloud-backup.log 2>&1
# =====================================================================
set -euo pipefail

# --- Configuración (se puede sobrescribir con variables de entorno) ---
BACKUP_DIR="${BACKUP_DIR:-/srv/backups/nextcloud}"
DATA_DIR="${DATA_DIR:-/srv/nextcloud/data}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
APP_CONTAINER="${APP_CONTAINER:-nextcloud}"
DB_CONTAINER="${DB_CONTAINER:-nextcloud-db}"

DATE="$(date +%F_%H%M)"
DB_FILE="${BACKUP_DIR}/nextcloud-db_${DATE}.sql.gz"
DATA_FILE="${BACKUP_DIR}/nextcloud-data_${DATE}.tar.gz"

log() { echo "[$(date '+%F %T')] $*"; }

occ() { docker exec -u www-data "$APP_CONTAINER" php occ "$@"; }

# Asegura que el modo mantenimiento se desactiva aunque el script falle
cleanup() {
  log "Desactivando modo mantenimiento"
  occ maintenance:mode --off || log "AVISO: no se pudo desactivar el modo mantenimiento"
}

mkdir -p "$BACKUP_DIR"
log "=== Inicio del backup ==="

log "Activando modo mantenimiento"
occ maintenance:mode --on
trap cleanup EXIT

# 1. Base de datos (usa las credenciales definidas en el propio contenedor)
log "Volcando base de datos -> ${DB_FILE}"
docker exec "$DB_CONTAINER" sh -c \
  'exec mysqldump --single-transaction -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' \
  | gzip > "$DB_FILE"

# 2. Datos, configuración y aplicaciones
log "Comprimiendo ${DATA_DIR} -> ${DATA_FILE}"
tar -czf "$DATA_FILE" -C "$DATA_DIR" .

# 3. Fin del modo mantenimiento
cleanup
trap - EXIT

# 4. Retención
log "Eliminando copias con más de ${RETENTION_DAYS} días"
find "$BACKUP_DIR" -maxdepth 1 -type f -name 'nextcloud-*' -mtime +"$RETENTION_DAYS" -print -delete

log "Tamaño de las copias generadas:"
du -h "$DB_FILE" "$DATA_FILE"
log "=== Backup completado ==="
