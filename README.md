# COMO DESPLEGAR N8N EN LA NUBE

Para desplegar n8n de forma exitosa en la nube debes seguir las siguientes instrucciones:

## Paso 1 - Apuntar dominio
Apunta tu dominio a la ip de tu servidor creando dos registros de tipo A.
- **A**: `n8n.tudominio.com` → `[IP_SERVIDOR]`
- **A**: `traefik.tudominio.com` → `[IP_SERVIDOR]`

## Paso 2 - Configurar Servidor
Para simplificar el curso he creado este repositorio para facilitar la instalación de n8n para usuarios no experimentados.

### Ingresar a tu servidor:
Puedes hacer uso de la consola de tu proveedor o acceder a tu servidor haciendo uso de ssh.
```bash
ssh root@[IP_SERVIDOR] # acceder a tu servidor
apt update && apt upgrade -y # actualizar tu servidor
```

Ahora deberemos instalar docker.
```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Instalar Docker Compose
apt install -y docker-compose-plugin
systemctl enable docker && systemctl start docker
```

Ahora instalamos git.
```bash
apt-get install git
```

Seguimos las siguientes instrucciones:
```bash
git clone https://github.com/Physicworld/n8n_cloud_deployment # Clonamos el repositorio
cd n8n_cloud_deployment # Entramos a la carpeta del repositorio
cp .env.example .env # Copiamos las variables
nano .env # Reemplazamos todas las variables por nuestros datos
```

## Paso 3 - Ejecutar instalación
Una vez configuradas las variables, ejecuta el script de instalación:
```bash
chmod +x setup.sh
./setup.sh
```

## Paso 4 - Verificar instalación
Verifica que todos los servicios estén funcionando:
```bash
docker compose ps
```

## Paso 5 - Acceder a N8N
Una vez completada la instalación, puedes acceder a:

- **N8N**: `https://n8n.tudominio.com`
  - Usuario: El configurado en `N8N_BASIC_AUTH_USER`
  - Contraseña: La configurada en `N8N_BASIC_AUTH_PASSWORD`

- **Traefik Dashboard**: `https://traefik.tudominio.com`
  - Usuario: `admin`
  - Contraseña: `admin`

## Comandos Útiles

### Ver logs
```bash
docker compose logs n8n -f
docker compose logs postgres -f
docker compose logs traefik -f
```

### Reiniciar servicios
```bash
docker compose restart n8n
docker compose restart postgres
docker compose restart traefik
```

### Actualizar N8N
```bash
docker compose pull n8n
docker compose up -d n8n
```

### Backup de datos
```bash
# Backup automático (recomendado)
bash scripts/backup.sh

# Backup manual de base de datos
docker compose exec postgres pg_dump -U n8n_user n8n > backup_$(date +%Y%m%d).sql
```

### Restaurar backup
```bash
# Restaurar usando el script (recomendado)
bash scripts/restore.sh nombre_del_backup.sql

# Restaurar manualmente
docker compose exec -T postgres psql -U n8n_user -d n8n < backup_FECHA.sql
```

### Programar backups automáticos
```bash
# Agregar a crontab para backup diario a las 2 AM
echo "0 2 * * * cd ~/n8n_cloud_deployment && bash scripts/backup.sh" | crontab -
```

## Solución de Problemas

### Los certificados SSL no se generan
```bash
# Verificar DNS
dig n8n.tudominio.com
dig traefik.tudominio.com

# Reiniciar Traefik
docker compose restart traefik
```

### N8N no carga
```bash
# Ver logs detallados
docker compose logs n8n --tail=50

# Verificar conexión a base de datos
docker compose exec postgres pg_isready -U n8n_user
```

### Los webhooks no funcionan
Verifica que `WEBHOOK_URL` en el archivo `.env` termine con `/`

## Estructura del Proyecto

```
n8n_cloud_deployment/
├── README.md
├── .env.example
├── docker-compose.yml
├── setup.sh
├── traefik/
│   └── traefik.yml
└── scripts/
    ├── backup.sh
    └── restore.sh
```

---

**¡Felicidades!** Ya tienes N8N funcionando en producción con PostgreSQL y SSL automático.