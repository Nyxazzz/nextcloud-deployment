# 🛠️ Instalación

Guía paso a paso para desplegar Nextcloud con Docker sobre Ubuntu Server 24.04.

← [Volver al README](../README.md) · Siguiente: [Configuración básica →](configuracion.md)

---

## Índice

1. [Requisitos previos](#1-requisitos-previos)
2. [Preparación del servidor](#2-preparación-del-servidor)
3. [Instalación de Docker](#3-instalación-de-docker)
4. [Despliegue](#4-despliegue)
5. [Puesta en marcha](#5-puesta-en-marcha)
6. [Comprobación](#6-comprobación)

---

## 1. Requisitos previos

- Servidor (físico o máquina virtual) con **Ubuntu Server 24.04 LTS**.
- Usuario con permisos de **sudo**.
- Conexión a Internet para descargar paquetes e imágenes.
- Recomendado: **IP fija** en la red local (y un dominio si se quiere acceso externo con HTTPS).

## 2. Preparación del servidor

### Actualización del sistema

```bash
sudo apt update && sudo apt upgrade -y
```

### Configurar la zona horaria y el nombre del equipo (opcional)

```bash
sudo timedatectl set-timezone Europe/Madrid
sudo hostnamectl set-hostname nextcloud-server
```

### Asignar IP fija (opcional, recomendado)

Edita el fichero de Netplan (el nombre puede variar):

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

Ejemplo (adapta la interfaz, IP y puerta de enlace a tu red):

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses: [192.168.1.50/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

```bash
sudo netplan apply
```

## 3. Instalación de Docker

Se instalan los componentes principales: **docker.io** (motor de Docker) y **Docker Compose**.

```bash
sudo apt install -y docker.io docker-compose-v2
```

> ℹ️ En Ubuntu 24.04 el paquete `docker-compose-v2` proporciona el comando `docker compose` (con espacio). Si usas el paquete antiguo `docker-compose`, el comando será `docker-compose` (con guion).

Habilitar Docker al arrancar e iniciarlo:

```bash
sudo systemctl enable --now docker
```

(Opcional) Permitir usar Docker sin `sudo` (requiere cerrar sesión y volver a entrar):

```bash
sudo usermod -aG docker $USER
```

Comprobar la instalación:

```bash
docker --version
docker compose version
```

## 4. Despliegue

### 4.1 Crear los directorios persistentes

Aquí se almacenarán la base de datos y los datos de Nextcloud, **fuera de los contenedores**, para que no se pierdan al actualizarlos o recrearlos:

```bash
sudo mkdir -p /srv/nextcloud/data /srv/nextcloud/db
```

| Ruta en el servidor | Contenido |
|---|---|
| `/srv/nextcloud/data` | Instalación de Nextcloud, configuración (`config/config.php`) y archivos de los usuarios |
| `/srv/nextcloud/db` | Ficheros de la base de datos MariaDB |

> 💡 Si el servidor tiene un segundo disco para datos, móntalo en `/srv/nextcloud` antes de continuar.

### 4.2 Obtener el `docker-compose.yml`

```bash
git clone https://github.com/Nyxazzz/nextcloud-deployment.git
cd nextcloud-deployment/docs
```

El fichero [`docker-compose.yml`](docker-compose.yml) define dos servicios:

| Servicio | Imagen | Contenedor | Función |
|---|---|---|---|
| `db` | `mariadb:10.5` | `nextcloud-db` | Base de datos |
| `app` | `nextcloud` | `nextcloud` | Aplicación web, publicada en el puerto **8080** |

### 4.3 Configuración de variables

Edita el fichero y cambia los valores marcados con `ESTE APARTADO SE DEBE CAMBIAR A SU GUSTO`:

```bash
nano docker-compose.yml
```

| Variable | Servicio | Descripción |
|---|---|---|
| `MYSQL_ROOT_PASSWORD` | `db` | Contraseña del usuario `root` de MariaDB |
| `MYSQL_DATABASE` | `db` y `app` | Nombre de la base de datos (por defecto `nextcloud`) |
| `MYSQL_USER` | `db` y `app` | Usuario de la base de datos que usará Nextcloud |
| `MYSQL_PASSWORD` | `db` y `app` | Contraseña de ese usuario |
| `MYSQL_HOST` | `app` | Nombre del servicio de base de datos (`db`) |

> ⚠️ `MYSQL_DATABASE`, `MYSQL_USER` y `MYSQL_PASSWORD` **deben ser idénticos** en ambos servicios.
>
> ⚠️ **No dejes las contraseñas por defecto (`admin`)**. Puedes generar una segura con:
> ```bash
> openssl rand -base64 24
> ```

## 5. Puesta en marcha

Una vez hecho todo lo anterior, desplegamos el servicio:

```bash
sudo docker compose up -d
```

La primera vez Docker descargará las imágenes, lo que puede tardar unos minutos.

## 6. Comprobación

Ver que los contenedores están en ejecución:

```bash
sudo docker compose ps
```

Salida esperada (aproximada):

```text
NAME           IMAGE          STATUS          PORTS
nextcloud      nextcloud      Up 2 minutes    0.0.0.0:8080->80/tcp
nextcloud-db   mariadb:10.5   Up 2 minutes    3306/tcp
```

Ver los logs si algo falla:

```bash
sudo docker compose logs -f
```

Abre en el navegador:

```text
http://IP_DEL_SERVIDOR:8080
```

Debería aparecer el asistente de instalación de Nextcloud. Continúa con la **[configuración básica →](configuracion.md)**.
