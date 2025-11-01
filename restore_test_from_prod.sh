#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURACIÓN ===
BACKUP_DIR="/root/public/x/x/backups"
DB_PROD="baseDeDatos"
DB_TEST="baseDeDatosTestDB"

# Detectar puerto real del clúster
PORT=$(sudo -u postgres psql -At -c "SHOW port;")

echo "=== Restauración de base de datos TEST desde PROD ==="
echo "Buscando último backup de ${DB_PROD}..."

# Buscar el archivo más reciente del patrón de PROD
LATEST_BACKUP=$(ls -1t ${BACKUP_DIR}/${DB_PROD}_backups_*.dump | head -n 1)

if [[ -z "${LATEST_BACKUP}" ]]; then
  echo "❌ No se encontró ningún backup de ${DB_PROD} en ${BACKUP_DIR}"
  exit 1
fi

echo "Último backup detectado: ${LATEST_BACKUP}"

# Confirmación opcional
read -p "¿Deseas restaurar este backup sobre ${DB_TEST}? (y/N): " confirm
if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
  echo "Operación cancelada."
  exit 0
fi

# === Terminar sesiones activas antes de DROP DATABASE ===
echo "🧹 Terminando sesiones activas en ${DB_TEST}..."
sudo -u postgres psql -p "$PORT" -d postgres -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${DB_TEST}' AND pid <> pg_backend_pid();
"

# === Proceso de restauración ===
echo "💣 Eliminando base de datos ${DB_TEST}..."
sudo -u postgres psql -p "$PORT" -d postgres -c "DROP DATABASE IF EXISTS \"${DB_TEST}\";"

echo "🧱 Creando base de datos ${DB_TEST}..."
sudo -u postgres psql -p "$PORT" -d postgres -c "CREATE DATABASE \"${DB_TEST}\" OWNER postgres;"

echo "♻️ Restaurando backup en ${DB_TEST}..."

# Copiar temporalmente el dump a /tmp con permisos correctos
TMP_DUMP="/tmp/$(basename "$LATEST_BACKUP")"

cp "$LATEST_BACKUP" "$TMP_DUMP"
chown postgres:postgres "$TMP_DUMP"
chmod 644 "$TMP_DUMP"

# Ejecutar restauración desde /tmp con flags adecuados
sudo -u postgres pg_restore \
  -p "$PORT" \
  -d "$DB_TEST" \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  --disable-triggers \
  --exit-on-error \
  "$TMP_DUMP"

# Limpiar archivo temporal
rm -f "$TMP_DUMP"

echo "✅ Restauración completada exitosamente."