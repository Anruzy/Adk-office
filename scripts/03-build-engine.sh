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
log "make (motor) con $(adk_jobs) trabajos"
make
log "Motor listo"
