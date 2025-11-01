#!/bin/bash
set -e

# Variables de configuración
APP_DIR="/root/public/x/x/x"
BUILD_DIR="build"
DEST_DIR="/var/www/x"
GIT_CMD="git"
NPM_CMD="npm"
SLEEP_SECONDS=1

cd "$APP_DIR" || { echo "No se puede acceder a $APP_DIR"; exit 1; }

echo ">>> Haciendo git pull en $APP_DIR..."
$GIT_CMD pull

echo ">>> Eliminando carpeta $BUILD_DIR..."
rm -rf "$BUILD_DIR/"

echo ">>> Instalando dependencias (comando: $NPM_CMD)..."
$NPM_CMD install -f

echo ">>> Compilando proyecto..."
$NPM_CMD run build

echo ">>> Copiando archivos compilados a $DEST_DIR ..."
rm -rf "$DEST_DIR"/*
cp -r "$BUILD_DIR"/* "$DEST_DIR"/

echo ">>> Despliegue completado ✅"