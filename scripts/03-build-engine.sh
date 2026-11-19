#!/usr/bin/env bash
# Compila el motor (LibreOffice/Collabora core) para Android.
# Es el paso largo: varias horas la primera vez; con ccache, mucho menos.
source "$(dirname "$0")/common.sh"

SDK="$(android_sdk)"
ENGINE="$ADK_SRC/engine"
[ -d "$ENGINE" ] || die "Falta $ENGINE; ejecuta primero 01-fetch-sources.sh"

log "Escribiendo engine/autogen.input ($ANDROID_ABI)"
{
    echo "--with-android-ndk=$SDK/ndk/$NDK_ENGINE_VERSION"
    echo "--with-android-sdk=$SDK"
    echo "--with-distro=$(engine_distro)"
    # Lo que va después de --with-distro sobrescribe al distro de Collabora.
    echo "--with-lang=$ADK_LANGS"
    echo "--with-vendor=$APP_VENDOR"
    echo "--with-external-tar=$ADK_TARBALLS"
    echo "--with-parallelism=$(adk_jobs)"
    if command -v ccache >/dev/null; then echo "--enable-ccache"; fi
    # Opciones extra sin tocar el script: ADK_ENGINE_EXTRA="--foo --bar"
    for o in ${ADK_ENGINE_EXTRA:-}; do echo "$o"; done
} > "$ENGINE/autogen.input"
cat "$ENGINE/autogen.input"

cd "$ENGINE"
log "autogen.sh (motor)"
./autogen.sh

# Arreglo: al compilar para Android con traducciones, el motor ejecuta
# "pocheck" (solo valida los .po) desde workdir_for_build, pero en la
# compilación cruzada esa herramienta no se construye para la máquina host
# y make falla con "pocheck: not found" (Error 127). Si no existe, se pone
# un sustituto que solo avisa. Si upstream llega a compilarla, gbuild la
# reenlaza encima y se usa la real.
if [ -n "$(echo "$ADK_LANGS" | tr ' ' '\n' | grep -v '^en-US$' || true)" ]; then
    POCHECK="$ENGINE/workdir_for_build/LinkTarget/Executable/pocheck"
    if [ ! -e "$POCHECK" ]; then
        warn "pocheck no está disponible para el host; se usa un sustituto"
        mkdir -p "$(dirname "$POCHECK")"
        printf '#!/bin/sh\necho "[adk-office] pocheck omitido (compilacion cruzada)" >&2\nexit 0\n' > "$POCHECK"
        chmod +x "$POCHECK"
    fi
fi

log "make (motor) con $(adk_jobs) trabajos"
make
log "Motor listo"
