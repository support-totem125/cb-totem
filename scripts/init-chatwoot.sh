#!/bin/bash
#
# Script de inicialización de Chatwoot v4.7.0
# Ejecuta migraciones de base de datos si es necesario
#

set -e

echo "🚀 Inicializando Chatwoot v4.7.0..."

# Cambiar al directorio de la aplicación
cd /app

# Esperar a que PostgreSQL esté listo
echo "⏳ Esperando a que PostgreSQL esté disponible..."
max_attempts=30
attempt=0
while ! pg_isready -h "${POSTGRES_HOST:-postgres}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}"; do
  attempt=$((attempt + 1))
  if [ $attempt -ge $max_attempts ]; then
    echo "❌ PostgreSQL no se conectó después de 30 intentos"
    exit 1
  fi
  echo "  PostgreSQL no está listo, esperando... ($attempt/$max_attempts)"
  sleep 2
done

echo "✅ PostgreSQL está disponible"

# Ejecutar migraciones
echo "🔄 Ejecutando migraciones de base de datos..."
if bundle exec rails db:migrate; then
  echo "✅ Migraciones completadas"
else
  echo "⚠️  Hubo un error en las migraciones, pero continuando..."
fi

echo "✅ Chatwoot inicializado correctamente"
echo ""
echo "🎉 ¡Iniciando servidor Chatwoot!"

# Ejecutar el servidor Rails directamente
exec bundle exec rails s -p 3000 -b 0.0.0.0
