#!/usr/bin/env bash
# Configura y compila la capa Collabora Office (kit, interfaz web, JNI) y
# empaqueta el APK con Gradle.
source "$(dirname "$0")/common.sh"

cd "$ADK_SRC"
"$ADK_ROOT/scripts/04-apply-overlay.sh"

VERSION_CODE="${ADK_VERSION_CODE:-${GITHUB_RUN_NUMBER:-1}}"

log "autogen.sh (Collabora Office)"
./autogen.sh

args=(--enable-androidapp
      --with-app-name="$APP_NAME"
      --with-vendor="$APP_VENDOR"
      --with-info-url="$APP_INFO_URL"
      --with-android-package-name="$APP_PACKAGE"
      --with-android-package-versioncode="$VERSION_CODE")
# Sin la marca de Collabora (sus logos son marcas registradas).
if ./configure --help | grep -q -- '--disable-branding'; then
    args+=(--disable-branding)
fi
for o in ${ADK_ONLINE_EXTRA:-}; do args+=("$o"); done

log "configure ${args[*]}"
./configure "${args[@]}"

log "make (Collabora Office)"
make -j"$(adk_jobs)"

log "Gradle"
cd android
TASKS=(assembleDebug)
if [ -n "${ADK_KEYSTORE:-}" ]; then TASKS+=(assembleRelease); fi
./gradlew --no-daemon "${TASKS[@]}"

mkdir -p "$ADK_OUT"
SAFE_NAME="$APP_FILE_NAME"

DEBUG_APK="$(find "$ADK_SRC" -path '*outputs/apk/debug/*.apk' -newer "$ADK_SRC/config.status" | head -1)"
[ -n "$DEBUG_APK" ] || die "Gradle no generó el APK de depuración"
cp "$DEBUG_APK" "$ADK_OUT/$SAFE_NAME-$ANDROID_ABI-debug.apk"

# APK de versión firmado, solo si hay llave (ADK_KEYSTORE = ruta al .jks).
if [ -n "${ADK_KEYSTORE:-}" ]; then
    SDK="$(android_sdk)"
    APKSIGNER="$(ls -d "$SDK"/build-tools/*/apksigner | sort -V | tail -1)"
    UNSIGNED="$(find "$ADK_SRC" -path '*outputs/apk/release/*.apk' -newer "$ADK_SRC/config.status" | head -1)"
    [ -n "$UNSIGNED" ] || die "Gradle no generó el APK de versión"
    "$APKSIGNER" sign --ks "$ADK_KEYSTORE" \
        --ks-pass env:ADK_KEYSTORE_PASSWORD \
        --ks-key-alias "${ADK_KEY_ALIAS:-adk}" \
        --key-pass env:ADK_KEY_PASSWORD \
        --out "$ADK_OUT/$SAFE_NAME-$ANDROID_ABI.apk" "$UNSIGNED"
fi

log "APK listo(s):"
ls -lh "$ADK_OUT"/*.apk
