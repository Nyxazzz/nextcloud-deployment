# 🩺 Solución de problemas

Errores frecuentes y cómo resolverlos.

← [Mantenimiento](mantenimiento.md) · [Volver al README](../README.md)

---

> Alias usado: `alias occ='sudo docker exec -u www-data nextcloud php occ'`

## No se puede acceder a `http://IP:8080`

1. Comprobar que los contenedores están en marcha: `sudo docker compose ps`.
2. Revisar los logs: `sudo docker compose logs app`.
3. Comprobar que el puerto escucha: `sudo ss -tlnp | grep 8080`.
4. Comprobar el firewall: `sudo ufw status` (abrir `8080/tcp` si se accede sin proxy).
5. Probar desde el propio servidor: `curl -I http://localhost:8080`.

## "Acceso a través de un dominio no confiable"

La IP o dominio usados no están en `trusted_domains`:

```bash
occ config:system:set trusted_domains 1 --value=IP_O_DOMINIO
```

Ver [configuración básica](configuracion.md#3-dominios-de-confianza).

## Error de conexión con la base de datos

- Verificar que `MYSQL_USER`, `MYSQL_PASSWORD` y `MYSQL_DATABASE` son **iguales** en los servicios `db` y `app`.
- Ver los logs de MariaDB: `sudo docker compose logs db`.
- Las variables `MYSQL_*` de MariaDB **solo se aplican la primera vez** (con `/srv/nextcloud/db` vacío). Si se cambian después, hay que cambiar la contraseña dentro de la base de datos o, en una instalación nueva sin datos, vaciar el directorio y volver a empezar.

## Nextcloud se queda en "modo mantenimiento"

Suele ocurrir si un backup o una actualización se interrumpe:

```bash
occ maintenance:mode --off
```

## Fallo al subir archivos grandes

- Revisar `client_max_body_size` en Nginx ([seguridad.md](seguridad.md#https)).
- Comprobar el espacio libre: `df -h /srv`.
- Comprobar la cuota del usuario.

## Bucle de redirección o enlaces `http://` estando detrás de HTTPS

Falta indicar a Nextcloud que está tras un proxy:

```bash
occ config:system:set overwriteprotocol --value=https
occ config:system:set overwrite.cli.url --value=https://nube.midominio.com
occ config:system:set trusted_proxies 0 --value=172.16.0.0/12
```

## Los archivos copiados al disco no aparecen

Nextcloud no detecta archivos copiados directamente en `/srv/nextcloud/data/data/<usuario>/files`. Hay que re-escanear:

```bash
occ files:scan --all
```

## Un usuario ha perdido el segundo factor (MFA)

```bash
occ twofactorauth:disable <usuario> totp
```

## Avisos en "Vista general" de administración

| Aviso | Solución |
|---|---|
| No se usa HTTPS | Configurar el proxy inverso con certificado ([seguridad.md](seguridad.md#https)) |
| Región de teléfono no configurada | `occ config:system:set default_phone_region --value=ES` |
| Faltan índices en la base de datos | `occ db:add-missing-indices` |
| Trabajos en segundo plano no ejecutados | Configurar cron ([configuración](configuracion.md#4-tareas-en-segundo-plano-cron)) |
| No hay caché de memoria configurada | Añadir Redis/APCu ([mejoras futuras](mejoras.md)) |
| Cabecera `Strict-Transport-Security` | Añadir HSTS en Nginx ([seguridad.md](seguridad.md#5-hsts-opcional-recomendado)) |

## Recursos

- Documentación oficial de administración: <https://docs.nextcloud.com/server/latest/admin_manual/>
- Imagen Docker oficial: <https://hub.docker.com/_/nextcloud>
- Foro de la comunidad: <https://help.nextcloud.com>
