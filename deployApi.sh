#!/bin/bash
set -e

# Variables de configuración
REPO_DIR="/root/public/talipot/bancos/api"
DIST_DIR="dist"
GIT_CMD="git"
NPM_CMD="npm"
FOREVER_CMD="forever"
SERVICE_UID="TALIPOT-BANCOS-API"
SLEEP_SECONDS=5

cd "$REPO_DIR" || exit 1

echo ">>> Haciendo git pull en $REPO_DIR..."
$GIT_CMD pull

echo ">>> Eliminando carpeta $DIST_DIR..."
rm -rf "$DIST_DIR/"

echo ">>> Instalando dependencias (comando: $NPM_CMD)..."
$NPM_CMD install -f

echo ">>> Compilando proyecto..."
$NPM_CMD run build

echo ">>> Reiniciando servicio con $FOREVER_CMD (uid: $SERVICE_UID)..."
$FOREVER_CMD stop "$SERVICE_UID" >/dev/null 2>&1 || true
$FOREVER_CMD start --uid "$SERVICE_UID" -a "$DIST_DIR/main.js"

echo ">>> Esperando $SLEEP_SECONDS segundos..."
sleep "$SLEEP_SECONDS"

echo ">>> Mostrando logs ($FOREVER_CMD)..."
$FOREVER_CMD logs 0