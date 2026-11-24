# 🗺️ Mejoras futuras

Líneas de evolución del proyecto, ordenadas por prioridad aproximada.

← [Volver al README](../README.md)

---

## Resumen

| Mejora | Categoría | Prioridad | Estado |
|---|---|---|---|
| Fail2Ban | Seguridad | 🔴 Alta | ⏳ Pendiente |
| Caché con Redis | Rendimiento | 🔴 Alta | ⏳ Pendiente |
| Monitorización | Operación | 🟠 Media | ⏳ Pendiente |
| Variables en fichero `.env` | Configuración | 🟠 Media | ⏳ Pendiente |
| Edición de documentos online | Funcionalidad | 🟡 Baja | ⏳ Pendiente |
| Integración LDAP | Usuarios | 🟡 Baja | ⏳ Pendiente |
| Alta disponibilidad | Infraestructura | 🟡 Baja | ⏳ Pendiente |

## Fail2Ban

Sistema de prevención de intrusiones que analiza los logs y **bloquea temporalmente las IPs** con demasiados intentos de inicio de sesión fallidos (en Nextcloud y en SSH).

- Leer el log `/srv/nextcloud/data/data/nextcloud.log` con un filtro para los errores `Login failed`.
- Proteger también el servicio `sshd`.

## Caché con Redis

Añadir un contenedor **Redis** al `docker-compose.yml` para la caché de memoria y el bloqueo de archivos. Mejora notablemente el rendimiento y elimina el aviso de "no hay caché de memoria configurada".

## Monitorización

- **Uptime Kuma**: aviso si el servicio deja de responder.
- **Prometheus + Grafana** (con *nextcloud-exporter*): uso de CPU, RAM, disco, usuarios activos.
- Alertas por correo o Telegram cuando el disco supere el 80 % o falle un backup.

## Variables en fichero `.env`

Mover las contraseñas del `docker-compose.yml` a un fichero `.env` (excluido del repositorio con `.gitignore`) para no publicar credenciales y facilitar el cambio de configuración.

## Edición de documentos online

Integrar **Collabora Online** o **OnlyOffice** para editar documentos de texto, hojas de cálculo y presentaciones directamente desde el navegador, de forma colaborativa.

## Integración LDAP

Conectar Nextcloud con un directorio **LDAP / Active Directory** existente para que los usuarios inicien sesión con sus credenciales corporativas y los grupos se sincronicen automáticamente.

## Alta disponibilidad

Para entornos donde la caída del servicio no es asumible:

- Varios nodos de Nextcloud detrás de un balanceador de carga.
- Base de datos replicada (MariaDB Galera).
- Almacenamiento compartido (NFS, Ceph) u objeto (S3/MinIO).
- Orquestación con Docker Swarm o Kubernetes.
