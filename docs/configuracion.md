# ⚙️ Configuración básica

Pasos a realizar una vez que los contenedores están en marcha.

← [Instalación](instalacion.md) · [Volver al README](../README.md) · Siguiente: [Gestión de usuarios →](usuarios.md)

---

## Índice

1. [Asistente inicial](#1-asistente-inicial)
2. [El comando `occ`](#2-el-comando-occ)
3. [Dominios de confianza](#3-dominios-de-confianza)
4. [Tareas en segundo plano (cron)](#4-tareas-en-segundo-plano-cron)
5. [Región del teléfono e idioma](#5-región-del-teléfono-e-idioma)
6. [Configuración de correo](#6-configuración-de-correo)
7. [Aplicaciones recomendadas](#7-aplicaciones-recomendadas)
8. [Clientes de escritorio y móvil](#8-clientes-de-escritorio-y-móvil)
9. [Revisar avisos de seguridad](#9-revisar-avisos-de-seguridad)

---

## 1. Asistente inicial

Al acceder por primera vez a `http://IP_DEL_SERVIDOR:8080` aparece el asistente:

1. Introduce un **nombre de usuario** y **contraseña** para la cuenta de **administrador**.
   - Evita nombres obvios como `admin`.
2. Si se solicita, selecciona **MySQL/MariaDB** como base de datos. Como las variables `MYSQL_*` ya están en el `docker-compose.yml`, normalmente se rellena automáticamente.
3. Pulsa **Instalar** y espera a que termine.
4. Opcionalmente, instala las **aplicaciones recomendadas** que ofrece el asistente.

## 2. El comando `occ`

`occ` es la herramienta de línea de comandos de Nextcloud. Se ejecuta **dentro del contenedor** con el usuario `www-data`:

```bash
sudo docker exec -u www-data nextcloud php occ <comando>
```

Ejemplos:

```bash
# Estado general de la instalación
sudo docker exec -u www-data nextcloud php occ status

# Listar todos los comandos disponibles
sudo docker exec -u www-data nextcloud php occ list
```

> 💡 Puedes crear un alias para escribir menos: `alias occ='sudo docker exec -u www-data nextcloud php occ'`

## 3. Dominios de confianza

Nextcloud solo responde a los nombres o IPs incluidos en `trusted_domains`. Si accedes con una IP o dominio diferente al de la instalación verás el error **"Acceso a través de un dominio no confiable"**.

Ver los dominios actuales:

```bash
sudo docker exec -u www-data nextcloud php occ config:system:get trusted_domains
```

Añadir la IP del servidor y el dominio (los índices `0`, `1`, `2`… son posiciones de la lista):

```bash
sudo docker exec -u www-data nextcloud php occ config:system:set trusted_domains 1 --value=192.168.1.50
sudo docker exec -u www-data nextcloud php occ config:system:set trusted_domains 2 --value=nube.midominio.com
```

También se puede editar directamente `/srv/nextcloud/data/config/config.php`.

## 4. Tareas en segundo plano (cron)

Nextcloud necesita ejecutar tareas periódicas (limpieza, notificaciones, escaneo…). El método recomendado es **cron** del sistema.

1. Configurar Nextcloud para usar cron:

   ```bash
   sudo docker exec -u www-data nextcloud php occ background:cron
   ```

2. Añadir la tarea al crontab del servidor:

   ```bash
   sudo crontab -e
   ```

   ```cron
   */5 * * * * docker exec -u www-data nextcloud php -f /var/www/html/cron.php
   ```

Se puede comprobar en **Configuración de administración → Ajustes básicos → Trabajos en segundo plano**.

## 5. Región del teléfono e idioma

Evita el aviso de "región de teléfono no configurada" y define el idioma por defecto:

```bash
sudo docker exec -u www-data nextcloud php occ config:system:set default_phone_region --value=ES
sudo docker exec -u www-data nextcloud php occ config:system:set default_language --value=es
sudo docker exec -u www-data nextcloud php occ config:system:set default_locale --value=es_ES
```

## 6. Configuración de correo

Para que Nextcloud envíe correos (recuperación de contraseña, notificaciones, enlaces compartidos):

**Configuración de administración → Ajustes básicos → Servidor de correo electrónico**

| Campo | Ejemplo |
|---|---|
| Modo de envío | SMTP |
| Cifrado | STARTTLS / SSL |
| Dirección del remitente | `nextcloud@midominio.com` |
| Servidor | `smtp.midominio.com` : `587` |
| Autenticación | Usuario y contraseña de la cuenta SMTP |

Usa el botón **Enviar correo** para probar la configuración (el administrador debe tener un email en su perfil).

## 7. Aplicaciones recomendadas

Desde **Aplicaciones** (menú del perfil) se pueden activar:

| Aplicación | Para qué sirve |
|---|---|
| **Two-Factor TOTP Provider** | Autenticación en dos pasos (ver [seguridad.md](seguridad.md#mfa)) |
| **Calendar / Contacts** | Calendario y agenda compartidos |
| **Deck** | Tableros tipo Kanban |
| **Talk** | Chat y videollamadas |
| **Group folders** | Carpetas compartidas por grupo con permisos |
| **Antivirus for files** | Escaneo de archivos (requiere ClamAV) |

## 8. Clientes de escritorio y móvil

| Plataforma | Descarga |
|---|---|
| Windows / macOS / Linux | <https://nextcloud.com/install/#install-clients> |
| Android | Google Play / F-Droid |
| iOS | App Store |

Al abrir el cliente se introduce la URL del servidor (`https://nube.midominio.com`) y se autoriza el acceso desde el navegador.

## 9. Revisar avisos de seguridad

En **Configuración de administración → Vista general** Nextcloud muestra advertencias de seguridad y configuración. Revisa este apartado tras cada cambio y sigue la guía de **[seguridad](seguridad.md)** para resolverlas (HTTPS, cabeceras, etc.).
