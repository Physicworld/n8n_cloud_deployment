#!/bin/bash

echo "🚀 Iniciando instalación de N8N..."

# Verificar que existe el archivo .env
if [ ! -f ".env" ]; then
    echo "❌ Error: No se encontró el archivo .env"
    echo "📝 Por favor ejecuta: cp .env.example .env"
    echo "📝 Y edita las variables necesarias"
    exit 1
fi

# Verificar que se configuró el dominio
if grep -q "tudominio.com" .env; then
    echo "❌ Error: Debes cambiar 'tudominio.com' por tu dominio real en .env"
    exit 1
fi

# Generar clave de encriptación si no existe
if grep -q "N8N_ENCRYPTION_KEY=$" .env; then
    echo "🔑 Generando clave de encriptación..."
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    sed -i "s/N8N_ENCRYPTION_KEY=$/N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env
    echo "✅ Clave de encriptación generada"
fi

# Crear directorio de Traefik si no existe
mkdir -p traefik

# Crear archivo acme.json para certificados SSL
echo "🔐 Configurando certificados SSL..."
touch traefik/acme.json
chmod 600 traefik/acme.json

# Crear directorios de datos
mkdir -p n8n_data postgres_data

# Establecer permisos
chmod 755 n8n_data postgres_data
chmod +x scripts/backup.sh scripts/restore.sh

echo "📦 Descargando imágenes de Docker..."
docker compose pull

echo "🔧 Iniciando servicios..."
docker compose up -d

echo "⏳ Esperando que los servicios se inicien..."
sleep 30

echo "📊 Verificando estado de los servicios..."
docker compose ps

echo ""
echo "🎉 ¡Instalación completada!"
echo ""
echo "📱 Accede a tus servicios:"
echo "   N8N: https://$(grep N8N_HOST .env | cut -d'=' -f2)"
echo "   Traefik: https://$(grep TRAEFIK_HOST .env | cut -d'=' -f2)"
echo ""
echo "👤 Credenciales N8N:"
echo "   Usuario: $(grep N8N_BASIC_AUTH_USER .env | cut -d'=' -f2)"
echo "   Contraseña: $(grep N8N_BASIC_AUTH_PASSWORD .env | cut -d'=' -f2)"
echo ""
echo "👤 Credenciales Traefik:"
echo "   Usuario: admin"
echo "   Contraseña: admin"
echo ""
echo "📋 Comandos útiles:"
echo "   Ver logs: docker compose logs n8n -f"
echo "   Reiniciar: docker compose restart n8n"
echo "   Parar: docker compose stop"
echo "   Actualizar: docker compose pull && docker compose up -d"
echo "   Backup: bash scripts/backup.sh"
echo "   Restaurar: bash scripts/restore.sh nombre_backup.sql"
echo ""
echo "🔍 Si hay problemas, revisa los logs con: docker compose logs"