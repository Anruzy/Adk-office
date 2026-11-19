#!/usr/bin/env bash
# Descarga el monorepo de Collabora Office (sin historial) y las traducciones.
source "$(dirname "$0")/common.sh"

shallow_fetch() {  # <url> <ref> <dir>
    local url=$1 ref=$2 dir=$3
    if [ ! -d "$dir/.git" ]; then
        git init -q "$dir"
        git -C "$dir" remote add origin "$url"
    fi
    git -C "$dir" fetch --depth 1 origin "$ref"
    git -C "$dir" checkout -q --force FETCH_HEAD
}

mkdir -p "$ADK_WORK" "$ADK_TARBALLS" "$ADK_OUT"

log "Monorepo: $COLLABORA_REPO @ $COLLABORA_REF"
shallow_fetch "$COLLABORA_REPO" "$COLLABORA_REF" "$ADK_SRC"
[ -d "$ADK_SRC/engine" ] || die "No existe engine/ en el monorepo: ¿cambió la estructura upstream?"

# Submódulos que pida el motor (p. ej. diccionarios), sin historial.
if [ -f "$ADK_SRC/.gitmodules" ] || [ -f "$ADK_SRC/engine/.gitmodules" ]; then
    log "Submódulos"
    git -C "$ADK_SRC" submodule update --init --recursive --depth 1 || \
        warn "Algunos submódulos no se pudieron descargar"
fi

# Traducciones: solo si se pidió algún idioma además de en-US.
if [ -n "$(echo "$ADK_LANGS" | tr ' ' '\n' | grep -v '^en-US$' || true)" ]; then
    if [ ! -d "$ADK_SRC/engine/translations/source" ]; then
        log "Traducciones: $TRANSLATIONS_REPO"
        shallow_fetch "$TRANSLATIONS_REPO" "${TRANSLATIONS_REF:-$COLLABORA_REF}" \
            "$ADK_SRC/engine/translations" || \
        shallow_fetch "$TRANSLATIONS_REPO" HEAD "$ADK_SRC/engine/translations"
    fi
fi

{
    echo "Adk-office: $(git -C "$ADK_ROOT" rev-parse HEAD 2>/dev/null || echo desconocido)"
    echo "Collabora Office ($COLLABORA_REPO): $(git -C "$ADK_SRC" rev-parse HEAD)"
    [ -d "$ADK_SRC/engine/translations/.git" ] && \
        echo "Traducciones: $(git -C "$ADK_SRC/engine/translations" rev-parse HEAD)"
    echo "ABI: $ANDROID_ABI · Idiomas: $ADK_LANGS"
} > "$ADK_OUT/FUENTES.txt"
cat "$ADK_OUT/FUENTES.txt"
