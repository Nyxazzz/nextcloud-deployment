# 🔒 Seguridad

Medidas para proteger el servidor y el servicio Nextcloud.

← [Gestión de usuarios](usuarios.md) · [Volver al README](../README.md) · Siguiente: [Backups →](backups.md)

---

## Índice

1. [Resumen de medidas](#resumen-de-medidas)
2. [Firewall](#firewall)
3. [HTTPS](#https)
4. [MFA](#mfa)
5. [Actualizaciones](#actualizaciones)
6. [Buenas prácticas adicionales](#buenas-prácticas-adicionales)
7. [Checklist](#checklist)

---

## Resumen de medidas

| Capa | Medida | Objetivo |
|---|---|---|
| Red | **UFW** | Solo exponer los puertos imprescindibles |
| Transporte | **HTTPS (TLS)** | Cifrar credenciales y datos en tránsito |
| Usuarios | **MFA** | Evitar accesos con contraseñas robadas |
| Sistema | **Actualizaciones** | Corregir vulnerabilidades conocidas |
| Datos | **[Backups](backups.md)** | Recuperarse ante fallos o ransomware |

## Firewall

Se utiliza **UFW** (Uncomplicated Firewall).

### Puertos

| Puerto | Uso | ¿Abrir? |
|---|---|---|
| `22/tcp` | SSH (administración) | ✅ Sí (idealmente solo desde la red local) |
| `80/tcp` | HTTP (redirección a HTTPS y validación de Let's Encrypt) | ✅ Sí |
| `443/tcp` | HTTPS | ✅ Sí |
| `8080/tcp` | Nextcloud directo, sin cifrar | ⚠️ Solo durante la instalación o en red local sin proxy |

### Configuración

```bash
# Política por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# ¡Permitir SSH antes de activar el firewall para no perder la conexión!
sudo ufw allow OpenSSH

# Web
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Solo si se accede directamente a Nextcloud sin proxy inverso
sudo ufw allow 8080/tcp

# Activar y comprobar
sudo ufw enable
sudo ufw status verbose
```

Restringir SSH a la red local (opcional):

```bash
sudo ufw delete allow OpenSSH
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
```

> ⚠️ **Docker y UFW**: Docker añade sus propias reglas de iptables y los puertos publicados en `docker-compose.yml` (como `8080:80`) **pueden quedar accesibles aunque UFW no los permita**. Si usas un proxy inverso, publica el puerto solo en local cambiando en el compose:
> ```yaml
> ports:
>   - 127.0.0.1:8080:80
> ```

## HTTPS

Certificados TLS para cifrar la conexión entre los usuarios y el servidor (contraseñas, archivos y datos de navegación).

La forma recomendada es colocar un **proxy inverso** (Nginx) delante de Nextcloud y obtener un certificado gratuito de **Let's Encrypt** con **Certbot**.

> Requisito: un **dominio** (ej. `nube.midominio.com`) que apunte a la IP pública del servidor y los puertos 80 y 443 redirigidos al servidor en el router.

### 1. Instalar Nginx y Certbot

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

### 2. Crear el sitio

```bash
sudo nano /etc/nginx/sites-available/nextcloud
```

```nginx
server {
    listen 80;
    server_name nube.midominio.com;

    # Tamaño máximo de subida
    client_max_body_size 10G;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_request_buffering off;
    }

    # Necesario para los clientes CalDAV/CardDAV
    location = /.well-known/carddav { return 301 $scheme://$host/remote.php/dav; }
    location = /.well-known/caldav  { return 301 $scheme://$host/remote.php/dav; }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### 3. Obtener el certificado

```bash
sudo certbot --nginx -d nube.midominio.com
```

Certbot modifica la configuración de Nginx para usar HTTPS y redirigir HTTP → HTTPS. La renovación es automática; se puede probar con:

```bash
sudo certbot renew --dry-run
```

### 4. Indicar a Nextcloud que está detrás de un proxy

```bash
alias occ='sudo docker exec -u www-data nextcloud php occ'

occ config:system:set trusted_domains 1 --value=nube.midominio.com
occ config:system:set overwrite.cli.url --value=https://nube.midominio.com
occ config:system:set overwriteprotocol --value=https
occ config:system:set trusted_proxies 0 --value=172.16.0.0/12
```

> `172.16.0.0/12` cubre las redes internas de Docker desde las que llegan las peticiones del proxy.

### 5. HSTS (opcional, recomendado)

Añade en el bloque `server { listen 443 ... }` que genera Certbot:

```nginx
add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
```

Comprueba el resultado en <https://scan.nextcloud.com> y <https://www.ssllabs.com/ssltest/>.

## MFA

Autenticación multifactor para aumentar la seguridad de los usuarios que van a usar el servicio de nube: aunque se robe una contraseña, sin el segundo factor no se puede entrar.

### Activación

1. Como administrador: **Aplicaciones → Seguridad → Two-Factor TOTP Provider → Activar**.
2. Cada usuario: **Configuración personal → Seguridad → Activar TOTP**, y escanear el código QR con una app de autenticación (Aegis, Google Authenticator, Microsoft Authenticator, FreeOTP…).
3. Guardar los **códigos de respaldo** en un lugar seguro.

### Hacerla obligatoria

**Configuración de administración → Seguridad → Autenticación en dos pasos → Forzar** (para todos o solo para ciertos grupos, por ejemplo administradores).

Por línea de comandos:

```bash
occ twofactorauth:enforce --on
occ twofactorauth:state <usuario>
```

> 🆘 Si un usuario pierde el segundo factor y sus códigos de respaldo, el administrador puede desactivarlo: `occ twofactorauth:disable <usuario> totp`

### Aplicaciones cliente

Los clientes de escritorio y móvil se autorizan desde el navegador (con MFA). Para otras aplicaciones (WebDAV, CalDAV) se generan **contraseñas de aplicación** en **Configuración personal → Seguridad → Dispositivos y sesiones**.

## Actualizaciones

Mantener actualizados tanto el servicio en la nube como el propio sistema operativo del servidor.

### Sistema operativo: actualizaciones automáticas de seguridad

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Nextcloud y MariaDB

Se actualizan descargando las nuevas imágenes. Ver el procedimiento completo en **[mantenimiento.md](mantenimiento.md#actualizar-nextcloud)**.

> ⚠️ Haz siempre un **[backup](backups.md)** antes de actualizar y **no saltes versiones mayores** de Nextcloud (ej. de 28 a 30 directamente).

## Buenas prácticas adicionales

- **SSH**: usar claves en lugar de contraseñas y deshabilitar el acceso de `root`
  (`PasswordAuthentication no` y `PermitRootLogin no` en `/etc/ssh/sshd_config`).
- **Contraseñas**: activar la app *Password policy* (longitud mínima, caracteres, comprobación contra contraseñas filtradas).
- **Protección contra fuerza bruta**: Nextcloud la incluye de serie; complementar con **Fail2Ban** ([mejoras futuras](mejoras.md)).
- **Secretos**: no subir al repositorio el `docker-compose.yml` con contraseñas reales.
- **Cifrado de disco**: valorar LUKS en el disco de datos si el servidor puede ser robado.
- **Registro**: revisar periódicamente **Configuración de administración → Registro** y `docker compose logs`.

## Checklist

- [ ] Contraseñas por defecto del `docker-compose.yml` cambiadas
- [ ] UFW activado con solo los puertos necesarios
- [ ] Puerto 8080 publicado solo en `127.0.0.1` (si hay proxy)
- [ ] HTTPS con certificado válido y redirección desde HTTP
- [ ] `trusted_domains`, `overwriteprotocol` y `trusted_proxies` configurados
- [ ] MFA activado y obligatorio para administradores
- [ ] Actualizaciones automáticas de seguridad del sistema
- [ ] SSH con claves y sin acceso root
- [ ] Backups automáticos y probados
- [ ] Sin avisos en *Configuración de administración → Vista general*
