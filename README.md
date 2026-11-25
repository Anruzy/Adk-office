# Adk-office · Office Móvil

Suite de ofimática **libre y de código abierto** para Android: documentos de
texto, hojas de cálculo, presentaciones y dibujos, sin conexión y sin cuentas.

Está basada en **Collabora Office para Android**, que a su vez usa el motor de
**LibreOffice**. Abre y guarda formatos ODF (`.odt`, `.ods`, `.odp`) y de
Microsoft Office (`.docx`, `.xlsx`, `.pptx`, `.doc`, `.xls`, `.ppt`), además de
exportar a PDF.

> Estado: **fase 1, base de compilación**. Ver [docs/ROADMAP.md](docs/ROADMAP.md).

## Cómo está armado

Este repositorio **no copia** los ~3 GB de código de Collabora/LibreOffice.
Guarda solo lo propio de Office Móvil y, al compilar, descarga el código
oficial y le aplica los cambios:

```
Adk-office/
├── config/adk.env          nombre, paquete, versión de Collabora, ABI, idiomas
├── overlay/                archivos que se copian encima del código original
│   └── android/…           íconos, textos y AdkStorage.java (SD)
├── scripts/
│   ├── 01-fetch-sources.sh   descarga el monorepo de Collabora (sin historial)
│   ├── 02-setup-android.sh   instala NDK, plataforma y build-tools
│   ├── 03-build-engine.sh    compila el motor LibreOffice para Android
│   ├── 04-apply-overlay.sh   aplica la personalización de Office Móvil
│   ├── 05-build-app.sh       compila la app y genera el APK
│   └── build-all.sh          todo lo anterior en orden
├── tools/gen-icons.py      regenera íconos y encabezado
└── .github/workflows/      compilación automática en GitHub Actions
```

Así, actualizar a una versión nueva de Collabora solo requiere cambiar
`COLLABORA_REF` en `config/adk.env`.

## Qué cambia respecto a Collabora Office

| Cambio | Detalle |
|---|---|
| Nombre e identidad | **Office Móvil**, paquete `io.github.anruzy.adkoffice`, ícono propio. No usa logos ni marcas de Collabora. |
| Tarjeta SD | Las copias de trabajo de documentos (al abrir, exportar e imprimir) van a la SD si hay una montada. Se puede desactivar en *Ajustes → Almacenamiento*. Los temporales viejos se limpian solos. |
| Instalación en SD | `installLocation="auto"`: en celulares con SD adoptada, la app se puede mover a la tarjeta desde *Ajustes de Android → Apps*. |
| Habilitar edición | Los archivos que llegan sin permiso de escritura (WhatsApp, correo, descargas) muestran arriba la barra *Solo lectura · Habilitar edición*, como la Vista protegida de Excel. Al tocarla se guarda una copia editable donde elijas y el documento pasa a modo edición. |
| Guardar como imagen | *Exportar como → Imagen (.png)* en documentos, hojas, presentaciones y dibujos, también en solo lectura. |
| Idiomas | Español e inglés (configurable en `ADK_LANGS`). |

Los documentos se abren y guardan con el selector de archivos de Android, por lo
que se puede trabajar directamente con archivos de la SD, de la memoria interna,
de USB OTG o de proveedores como Drive.

## Obtener el APK

**GitHub Actions** compila el APK en cada push a `main` y lo deja como artefacto
descargable (*Actions → Compilar APK → office-movil-arm64-v8a*). Al crear una
etiqueta `v*` (por ejemplo `v0.1.0`) además se publica en *Releases*.

La primera compilación del motor tarda varias horas y puede pasar del límite de
6 h de GitHub. Si pasa, la caché se guarda igual: vuelve a lanzar el flujo
(*Re-run jobs*) y continuará casi donde se quedó.

Para compilar en tu propia máquina Linux, ver [docs/COMPILAR.md](docs/COMPILAR.md).

## Licencia

Mozilla Public License 2.0 (ver [LICENSE](LICENSE)), igual que Collabora Office
y LibreOffice. Créditos y avisos en [NOTICE.md](NOTICE.md).
