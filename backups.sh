#!/usr/bin/env bash
set -euo pipefail

# Directorio destino de los dumps
BACKUP_DIR="/root/public/x/x/backups"

# Bases a respaldar
DBS=("baseDeDatos" "baseDeDatosTestDB")

# Sello de tiempo (zona Mazatlán) -> aaaa_mm_dd_hhmm
STAMP=$(TZ=America/Mazatlan date +%Y_%m_%d_%H%M)

# Detectar el puerto real del clúster (p.ej. 3355)
PORT=$(sudo -u postgres psql -At -c "SHOW port;")

mkdir -p "$BACKUP_DIR"
umask 0077

for db in "${DBS[@]}"; do
  OUT="${BACKUP_DIR}/${db}_backups_${STAMP}.dump"
  echo "[$(date -Is)] Dump ${db} -> ${OUT}"
  # Importante: SIN -f; redirección la hace root para evitar 'Permission denied' bajo /root
  sudo -u postgres pg_dump -p "$PORT" -Fc --no-owner --no-privileges -d "$db" > "$OUT"
done