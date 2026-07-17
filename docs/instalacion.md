# Instalación

## Preparación del servidor

- Actualización del sistema
- Instalación de Docker y sus componentes principales(docker.io y docker-compose)

## Despliegue

- Crear los directorios donde se van a almacenar la base de datos y los datos de Nextcloud
- Creación de docker-compose.yml
- Configuración de variables

## Puesta en marcha
Una vez hecho todo lo anterior, deplegaremos el servicio para configuracion de usuarios y comenzar a usarlo
```bash
docker compose up -d
