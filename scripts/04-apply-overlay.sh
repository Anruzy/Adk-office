#!/usr/bin/env bash
# Aplica la personalización de Adk-office sobre el código de Collabora:
#   1. Copia overlay/ encima del árbol (íconos, textos, clases nuevas).
#   2. Ediciones puntuales con perl: archivos temporales grandes a la SD
#      y opción en Ajustes. Cada edición avisa si upstream cambió y no aplica.
# Es idempotente: se puede ejecutar varias veces.
source "$(dirname "$0")/common.sh"

[ -d "$ADK_SRC/android" ] || die "Falta $ADK_SRC/android"

log "Copiando overlay/"
cp -a "$ADK_ROOT/overlay/." "$ADK_SRC/"

LIBJAVA="$ADK_SRC/android/lib/src/main/java/org/libreoffice/androidlib"

# Sustituye <cacheDir> por AdkStorage.documentCacheDir(<ctx>) solo en los
# File.createTempFile("LibreOffice", ...) y en el PDF de impresión: son las
# copias completas de documentos. El perfil interno del motor no se mueve.
patch_file() {  # <archivo> <expr-perl> <descripción>
    local f=$1 expr=$2 what=$3 n
    [ -f "$f" ] || { warn "No existe $f ($what)"; return; }
    n=$(perl -0777 -i -pe "\$c += ($expr); END { print STDERR \$c+0 }" "$f" 2>&1 >/dev/null | tail -1)
    if [ "${n:-0}" -gt 0 ]; then
        echo "  ✓ $what ($n cambios)"
    elif grep -q "AdkStorage" "$f"; then
        echo "  ✓ $what (ya aplicado)"
    else
        warn "$what: no se encontró el patrón; revisa $f"
    fi
}

log "Archivos temporales de documentos → SD si hay"
patch_file "$LIBJAVA/LOActivity.java" \
    's/(File\.createTempFile\(\s*"LibreOffice"\s*,[^;]*?,\s*)(?:([\w.]+)\.)?getCacheDir\(\)\)/$1 . "AdkStorage.documentCacheDir(" . ($2 \/\/ "this") . "))"/ge' \
    "LOActivity: copias temporales"
patch_file "$LIBJAVA/PrintAdapter.java" \
    's/new File\(\s*(\w+)\.getCacheDir\(\)\s*,\s*"print\.pdf"\s*\)/new File(AdkStorage.documentCacheDir($1), "print.pdf")/g' \
    "PrintAdapter: PDF de impresión"

log "Opción en Ajustes"
PREFS="$ADK_SRC/android/app/src/main/res/xml/libreoffice_preferences.xml"
if [ -f "$PREFS" ] && ! grep -q adk_use_sd_cache "$PREFS"; then
    perl -0777 -i -pe 's{</PreferenceScreen>\s*$}{    <PreferenceCategory
        android:title="\@string/adk_storage_category"
        app:iconSpaceReserved="false">
        <SwitchPreferenceCompat
            android:defaultValue="true"
            android:key="adk_use_sd_cache"
            android:summary="\@string/adk_use_sd_cache_summary"
            android:title="\@string/adk_use_sd_cache_title"
            app:iconSpaceReserved="false" />
    </PreferenceCategory>
</PreferenceScreen>
}s' "$PREFS"
    grep -q adk_use_sd_cache "$PREFS" && echo "  ✓ Interruptor 'Usar tarjeta SD'" || \
        warn "No se pudo añadir el interruptor a $PREFS"
else
    echo "  ✓ Interruptor (ya aplicado o archivo ausente)"
fi

log "Habilitar edición en solo lectura y exportar como imagen (Android)"
perl "$ADK_ROOT/scripts/patches/apply.pl" "$ADK_ROOT/scripts/patches/loactivity.pl" \
    "$LIBJAVA/LOActivity.java"

log "Exportar como imagen (menú de la interfaz)"
perl "$ADK_ROOT/scripts/patches/apply.pl" "$ADK_ROOT/scripts/patches/menubar.pl" \
    "$ADK_SRC/browser/src/control/Control.Menubar.ts"

log "Instalación movible a la SD"
MANIFEST="$ADK_SRC/android/app/src/main/AndroidManifest.xml"
if grep -q 'android:installLocation=' "$MANIFEST"; then
    perl -i -pe 's/android:installLocation="[^"]*"/android:installLocation="auto"/' "$MANIFEST"
else
    perl -0777 -i -pe 's/<manifest(\s)/<manifest android:installLocation="auto"$1/' "$MANIFEST"
fi
grep -q 'installLocation="auto"' "$MANIFEST" && echo "  ✓ installLocation=auto"
