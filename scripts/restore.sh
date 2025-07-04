#!/bin/bash

# Script de restauración para N8N
# Verificar que se proporcionó un archivo de backup
if [ $# -eq 0 ]; then
    echo "❌ Error: Debes especificar el archivo de backup"
    echo "📝 Uso: bash scripts/restore.sh nombre_del_backup.sql"
    echo "📁 Backups disponibles:"
    ls -la $HOME/backups/*.sql 2>/dev/null || echo "   No hay backups disponibles"
    exit 1
fi

BACKUP_FILE="$1"

# Verificar si es ruta absoluta o relativa
if [[ "$BACKUP_FILE" = /* ]]; then
    # Es ruta absoluta
    BACKUP_PATH="$BACKUP_FILE"
else
    # Es solo nombre de archivo, agregar ruta de backups
    BACKUP_PATH="$HOME/backups/$BACKUP_FILE"
fi

# Verificar que el archivo existe
if [ ! -f "$BACKUP_PATH" ]; then
    echo "❌ Error: No se encontró el archivo $BACKUP_PATH"
    echo "📁 Backups disponibles:"
    ls -la $HOME/backups/*.sql 2>/dev/null || echo "   No hay backups disponibles"
    exit 1
fi

echo "🔄 Iniciando restauración de N8N..."
echo "📄 Archivo: $BACKUP_PATH"

# Confirmar restauración
echo "⚠️  ADVERTENCIA: Esta operación sobrescribirá la base de datos actual"
read -p "¿Continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Restauración cancelada"
    exit 1
fi

# Parar N8N temporalmente
echo "⏸️  Pausando N8N..."
docker compose stop n8n

# Esperar a que N8N se detenga completamente
sleep 5

# Verificar que PostgreSQL esté corriendo
echo "🔍 Verificando PostgreSQL..."
docker compose exec postgres pg_isready -U n8n_user -d n8n
if [ $? -ne 0 ]; then
    echo "❌ Error: PostgreSQL no está disponible"
    echo "🔧 Iniciando PostgreSQL..."
    docker compose up -d postgres
    sleep 10
fi

# Limpiar base de datos actual
echo "🧹 Limpiando base de datos actual..."
docker compose exec postgres psql -U n8n_user -d n8n -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

if [ $? -eq 0 ]; then
    echo "✅ Base de datos limpiada"
else
    echo "❌ Error al limpiar base de datos"
    exit 1
fi

# Restaurar backup
echo "📥 Restaurando backup..."
docker compose exec -T postgres psql -U n8n_user -d n8n < "$BACKUP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Backup restaurado exitosamente"
else
    echo "❌ Error al restaurar backup"
    exit 1
fi

# Reiniciar N8N
echo "🔄 Reiniciando N8N..."
docker compose up -d n8n

# Esperar a que N8N se inicie
echo "⏳ Esperando que N8N se inicie..."
sleep 15

# Verificar que todo esté funcionando
echo "🔍 Verificando servicios..."
docker compose ps

echo ""
echo "🎉 Restauración completada exitosamente!"
echo ""
echo "📱 Servicios disponibles:"
echo "   N8N: https://$(grep N8N_HOST .env | cut -d'=' -f2)"
echo "   Traefik: https://$(grep TRAEFIK_HOST .env | cut -d'=' -f2)"
echo ""
echo "💡 Comandos útiles:"
echo "   Ver logs: docker compose logs n8n -f"
echo "   Estado: docker compose ps"
echo ""
echo "⚠️  Nota: Si N8N no responde inmediatamente, espera 1-2 minutos"