#!/bin/bash

# Script de backup para N8N
# Crear directorio de backups si no existe
mkdir -p ~/backups

# Obtener fecha actual
DATE=$(date +%Y%m%d_%H%M%S)

echo "🔄 Iniciando backup de N8N..."
echo "📅 Fecha: $DATE"

# Crear backup de la base de datos
echo "💾 Creando backup de PostgreSQL..."
docker compose exec postgres pg_dump -U n8n_user n8n > ~/backups/n8n_db_$DATE.sql

if [ $? -eq 0 ]; then
    echo "✅ Backup de base de datos creado: ~/backups/n8n_db_$DATE.sql"
else
    echo "❌ Error al crear backup de base de datos"
    exit 1
fi

# Crear backup completo de archivos
echo "📦 Creando backup completo de archivos..."
tar -czf ~/backups/n8n_complete_$DATE.tar.gz \
    -C ~/ \
    --exclude='n8n_cloud_deployment/n8n_data/logs' \
    --exclude='n8n_cloud_deployment/postgres_data/pg_log' \
    n8n_cloud_deployment/n8n_data \
    n8n_cloud_deployment/postgres_data \
    n8n_cloud_deployment/.env

if [ $? -eq 0 ]; then
    echo "✅ Backup completo creado: ~/backups/n8n_complete_$DATE.tar.gz"
else
    echo "❌ Error al crear backup completo"
    exit 1
fi

# Mostrar tamaño de los backups
echo ""
echo "📊 Información de backups:"
echo "   DB: $(ls -lh ~/backups/n8n_db_$DATE.sql | awk '{print $5}')"
echo "   Completo: $(ls -lh ~/backups/n8n_complete_$DATE.tar.gz | awk '{print $5}')"

# Limpiar backups antiguos (mantener últimos 7 días)
echo "🧹 Limpiando backups antiguos..."
find ~/backups -name "n8n_db_*.sql" -mtime +7 -delete
find ~/backups -name "n8n_complete_*.tar.gz" -mtime +7 -delete

echo ""
echo "🎉 Backup completado exitosamente!"
echo "📁 Ubicación: ~/backups/"
echo ""
echo "💡 Para restaurar:"
echo "   bash scripts/restore.sh n8n_db_$DATE.sql"