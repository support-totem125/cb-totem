#!/bin/bash
#
# Script de inicialización de Chatwoot
# Ejecuta migraciones de base de datos si es necesario
# Este script debe estar montado en el contenedor de Chatwoot en /scripts/init-chatwoot.sh
#

set -e

echo "🚀 Inicializando Chatwoot..."

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
if bundle exec rails db:migrate 2>&1; then
  echo "✅ Migraciones completadas"
else
  echo "❌ Error durante las migraciones"
  exit 1
fi

echo "✅ Chatwoot inicializado correctamente"
echo ""
echo "🎉 ¡Iniciando servidor Chatwoot!"

# Ejecutar el servidor Rails
# Usar el entrypoint original y luego el comando
exec /app/docker/entrypoints/rails.sh bundle exec rails s -p 3000 -b 0.0.0.0
