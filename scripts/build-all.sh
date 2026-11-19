#!/usr/bin/env bash
# Compilación completa en una máquina Linux propia.
# Requisitos: ~40 GB libres, 16 GB de RAM recomendados, JDK 17+, Node 22,
# y las dependencias de compilación de LibreOffice (ver docs/COMPILAR.md).
source "$(dirname "$0")/common.sh"
d="$ADK_ROOT/scripts"
"$d/01-fetch-sources.sh"
"$d/02-setup-android.sh"
"$d/03-build-engine.sh"
"$d/05-build-app.sh"
