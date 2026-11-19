#!/usr/bin/env bash
# Instala los componentes del SDK de Android que necesita el build:
# NDK del motor, NDK de la app (el que pida android/app/build.gradle),
# plataforma y build-tools.
source "$(dirname "$0")/common.sh"

SDK="$(android_sdk)"
SDKMANAGER=""
for c in "$SDK/cmdline-tools/latest/bin/sdkmanager" "$SDK"/cmdline-tools/*/bin/sdkmanager; do
    [ -x "$c" ] && { SDKMANAGER="$c"; break; }
done

if [ -z "$SDKMANAGER" ]; then
    log "Instalando cmdline-tools en $SDK"
    mkdir -p "$SDK/cmdline-tools"
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/tools.zip" \
        "https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
    unzip -q "$tmp/tools.zip" -d "$tmp"
    rm -rf "$SDK/cmdline-tools/latest"
    mv "$tmp/cmdline-tools" "$SDK/cmdline-tools/latest"
    rm -rf "$tmp"
    SDKMANAGER="$SDK/cmdline-tools/latest/bin/sdkmanager"
fi

GRADLE_FILE="$ADK_SRC/android/app/build.gradle"
APP_NDK="$(sed -n 's/.*ndkVersion[ =]*"\([0-9.]*\)".*/\1/p' "$GRADLE_FILE" | head -1)"
COMPILE_SDK="$(sed -n 's/.*compileSdk[ =]*\([0-9]*\).*/\1/p' "$GRADLE_FILE" | head -1)"
: "${COMPILE_SDK:=36}"

pkgs=("platform-tools" "platforms;android-$COMPILE_SDK" "build-tools;$COMPILE_SDK.0.0"
      "ndk;$NDK_ENGINE_VERSION")
[ -n "$APP_NDK" ] && [ "$APP_NDK" != "$NDK_ENGINE_VERSION" ] && pkgs+=("ndk;$APP_NDK")

log "SDK: $SDK"
log "Paquetes: ${pkgs[*]}"
yes | "$SDKMANAGER" --sdk_root="$SDK" --licenses >/dev/null || true
"$SDKMANAGER" --sdk_root="$SDK" --install "${pkgs[@]}" | grep -v '^\[=*' || true
