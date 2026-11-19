# shellcheck shell=bash
# Funciones y variables comunes. Se carga con: source "$(dirname "$0")/common.sh"
set -euo pipefail

ADK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ADK_ROOT
# shellcheck source=../config/adk.env
source "$ADK_ROOT/config/adk.env"
export COLLABORA_REPO TRANSLATIONS_REPO COLLABORA_REF ANDROID_ABI \
       NDK_ENGINE_VERSION ADK_LANGS APP_NAME APP_FILE_NAME APP_PACKAGE APP_VENDOR \
       APP_INFO_URL ADK_WORK ADK_SRC ADK_TARBALLS ADK_OUT

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[aviso] %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m[error] %s\033[0m\n' "$*" >&2; exit 1; }

# Distro de configuración del motor según la ABI.
engine_distro() {
    case "$ANDROID_ABI" in
        arm64-v8a)   echo CPAndroidAarch64 ;;
        armeabi-v7a) echo CPAndroid ;;
        x86_64)      echo CPAndroidX86_64 ;;
        x86)         echo CPAndroidX86 ;;
        *) die "ABI no soportada: $ANDROID_ABI" ;;
    esac
}

# Ubicación del SDK de Android (GitHub Actions define ANDROID_HOME).
android_sdk() {
    local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
    echo "$sdk"
}

adk_jobs() { echo "${ADK_JOBS:-$(nproc)}"; }
