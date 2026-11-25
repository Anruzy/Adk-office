# Parches de Adk-office para android/lib/.../LOActivity.java  (MPL-2.0)
# Ver scripts/patches/apply.pl para el formato.
use strict;
use warnings;

my $enable_editing = <<'JAVA';

    /**
     * Adk-office: "Habilitar edición" para documentos abiertos en solo
     * lectura (p. ej. recibidos por WhatsApp o correo). Guarda una copia
     * editable donde elija el usuario y pasa a modo edición (REQUEST_COPY).
     */
    void adkEnableEditing() {
        if (canDocumentBeExported()) {
            createNewFileInputDialog(mActivity, getFileName(true), getMimeType(), REQUEST_COPY);
        } else {
            String extension = getOdfExtensionForDocType(getMimeType());
            createNewFileInputDialog(mActivity, getFileName(false) + "." + extension,
                                     getMimeForFormat(extension), REQUEST_COPY);
        }
    }
JAVA

(
    # --- Guardar como imagen (PNG) -----------------------------------------
    {
        desc   => 'PNG: código de solicitud',
        marker => 'REQUEST_SAVEAS_PNG = ',
        try    => [ sub {
            s/(\n([ \t]*)public static final int REQUEST_SAVEAS_EPUB = \d+;)/$1\n$2public static final int REQUEST_SAVEAS_PNG = 2780; \/\/ adk-office/
        } ],
    },
    {
        desc   => 'PNG: resultado del selector de archivo',
        marker => '// adk:png-result',
        try    => [ sub {
            s/(\n([ \t]*)case REQUEST_SAVEAS_EPUB:)([ \t]*\n[ \t]*if \(intent == null\))/$1\n$2case REQUEST_SAVEAS_PNG: \/\/ adk:png-result$3/
        } ],
    },
    {
        desc   => 'PNG: formato por código',
        marker => '// adk:png-format',
        try    => [ sub {
            s/(\n([ \t]*)case REQUEST_SAVEAS_EPUB: return "epub";)/$1\n$2case REQUEST_SAVEAS_PNG: return "png"; \/\/ adk:png-format/
        } ],
    },
    {
        desc   => 'PNG: código por formato',
        marker => '// adk:png-id',
        try    => [ sub {
            s/(\n([ \t]*)case "epub": return REQUEST_SAVEAS_EPUB;)/$1\n$2case "png": return REQUEST_SAVEAS_PNG; \/\/ adk:png-id/
        } ],
    },
    {
        desc   => 'PNG: tipo MIME',
        marker => '// adk:png-mime',
        try    => [ sub {
            s/(\n([ \t]*)case "epub": return "application\/epub\+zip";)/$1\n$2case "png": return "image\/png"; \/\/ adk:png-mime/
        } ],
    },

    # --- Habilitar edición en solo lectura -----------------------------------
    {
        desc   => 'Solo lectura: método adkEnableEditing()',
        marker => 'void adkEnableEditing()',
        try    => [
            sub { s/(\n[ \t]*private void requestForCopy\(\))/$enable_editing$1/ },
            # Alternativa: antes del cierre final de la clase.
            sub { s/(\n\}\s*(?:\/\*[^\n]*\*\/\s*)?\z)/$enable_editing$1/ },
        ],
    },
    {
        desc   => 'Solo lectura: barra al terminar de cargar',
        marker => 'AdkReadOnlyBar.onDocumentShown',
        try    => [
            sub {
                s/(case "hideProgressbar": \{[ \t]*\n([ \t]*)if \(mProgressDialog != null\)[ \t]*\n[ \t]*mProgressDialog\.dismiss\(\);)/$1\n$2AdkReadOnlyBar.onDocumentShown(LOActivity.this, isDocEditable, canDocumentBeExported());/
            },
            sub {
                s/(case "hideProgressbar": \{[ \t]*\n([ \t]*))/$1AdkReadOnlyBar.onDocumentShown(LOActivity.this, isDocEditable, canDocumentBeExported());\n$2/
            },
        ],
    },
    {
        desc   => 'Solo lectura: reiniciar barra al abrir otro documento',
        marker => 'AdkReadOnlyBar.reset()',
        try    => [ sub {
            s/(\n([ \t]*)private void loadDocument\(\) \{[ \t]*\n)/$1$2    AdkReadOnlyBar.reset();\n/
        } ],
    },
);
