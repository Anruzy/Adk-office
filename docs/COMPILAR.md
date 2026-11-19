# Compilar Office Móvil en Linux

Solo hace falta para compilar fuera de GitHub Actions.

## Requisitos

| Recurso | Mínimo | Notas |
|---|---|---|
| Disco | ~40 GB libres | Código ~3 GB, compilación del motor 25–35 GB |
| RAM | 8 GB (16 GB recomendado) | |
| Tiempo | 2–6 h la primera vez | Depende de los núcleos; con ccache, mucho menos después |
| SO | Linux x86_64 (Debian/Ubuntu probado en CI) | macOS también funciona según Collabora |

El trabajo pesado va a `work/` dentro del repositorio. Para usar otro disco
(por ejemplo uno externo con más espacio):

```bash
export ADK_WORK=/media/disco/adk-work
export ADK_TARBALLS=/media/disco/adk-tarballs
```

### Paquetes (Debian/Ubuntu)

```bash
sudo apt-get install autoconf automake autopoint bison ccache flex gettext gperf \
  libtool m4 make nasm pkgconf zip unzip xsltproc libxml2-utils libxml2-dev \
  libxslt1-dev libssl-dev libpng-dev libcap-dev libpam0g-dev libkrb5-dev \
  libnss3-dev libcups2-dev libfontconfig1-dev libcppunit-dev libzstd-dev \
  python3-dev python3-lxml python3-polib openjdk-17-jdk
```

Además: Node.js 22 y el SDK de Android (`ANDROID_HOME`). Si no tienes SDK,
`02-setup-android.sh` instala las herramientas de línea de comandos en
`~/Android/Sdk`.

## Pasos

```bash
scripts/build-all.sh
```

o por partes:

```bash
scripts/01-fetch-sources.sh    # código de Collabora (+ traducciones)
scripts/02-setup-android.sh    # NDK / plataforma / build-tools
scripts/03-build-engine.sh     # motor (lo más largo)
scripts/05-build-app.sh        # aplica overlay, compila y empaqueta el APK
```

El APK queda en `out/`. En `out/FUENTES.txt` se anotan los commits exactos de
Collabora usados, para poder reproducir el build.

## Variables útiles

| Variable | Por defecto | Para qué |
|---|---|---|
| `COLLABORA_REF` | `main` | Rama/etiqueta/commit de Collabora |
| `ANDROID_ABI` | `arm64-v8a` | `armeabi-v7a` para celulares de 32 bits |
| `ADK_LANGS` | `en-US es` | Idiomas de la interfaz |
| `ADK_JOBS` | núcleos | Trabajos en paralelo |
| `ADK_ENGINE_EXTRA` | — | Opciones extra para `autogen.input` del motor |
| `ADK_ONLINE_EXTRA` | — | Opciones extra para `configure` de la app |
| `ADK_KEYSTORE` | — | Ruta a un `.jks` para firmar el APK de versión |

## Firmar el APK de versión

Sin llave solo se genera el APK de depuración (instalable, pero con el sufijo
"Debug"). Para publicar:

```bash
keytool -genkeypair -v -keystore office-movil.jks -alias adk \
  -keyalg RSA -keysize 4096 -validity 10000
```

En GitHub, guarda en *Settings → Secrets → Actions*:

- `ADK_KEYSTORE_BASE64`: salida de `base64 -w0 office-movil.jks`
- `ADK_KEYSTORE_PASSWORD`, `ADK_KEY_ALIAS` (`adk`), `ADK_KEY_PASSWORD`

**Nunca subas el `.jks` al repositorio.** Si se pierde, no podrás publicar
actualizaciones que se instalen encima de las anteriores.
