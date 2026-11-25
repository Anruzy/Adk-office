# Parches de Adk-office para browser/src/control/Control.Menubar.ts  (MPL-2.0)
# Agrega "Imagen (.png)" al menú "Exportar como" de la app móvil.
use strict;
use warnings;

# Texto en el idioma del celular (la cadena no existe en las traducciones
# de Collabora, así que no se usa _()).
my $label = q{(String(navigator.language || '').toLowerCase().startsWith('es') ? 'Imagen (.png)' : 'Image (.png)')};
my $item  = "{name: $label, id: 'downloadas-png', type: 'action'}, /* adk:png-menu */";

(
    {
        # Tras "PDF Document (.pdf) as..." en cada menú "Exportar como".
        desc   => 'Menú: Imagen (.png) en Exportar como',
        marker => 'adk:png-menu',
        # Solo en los menús móviles (mobiletext, mobilepresentation,
        # mobiledrawing, mobilespreadsheet), que van después de "mobiletext:".
        try    => [
            sub {
                return 0 unless /\bmobiletext\s*:\s*\[/g;
                my $i = $-[0];
                pos($_) = undef;
                my $tail = substr($_, $i);
                my $n = ($tail =~ s/(\n([ \t]*)\{name: _\('PDF Document \(\.pdf\) as\.\.\.'\), id: 'exportpdf'[^\n]*\},)/$1\n$2$item/g);
                substr($_, $i) = $tail if $n;
                return $n;
            },
            sub {
                return 0 unless /\bmobiletext\s*:\s*\[/g;
                my $i = $-[0];
                pos($_) = undef;
                my $tail = substr($_, $i);
                my $n = ($tail =~ s/(\n([ \t]*)\{name: _\('PDF Document \(\.pdf\)'\), id: !window\.ThisIsAMobileApp \? 'exportdirectpdf' : 'downloadas-pdf'[^\n]*\},)/$1\n$2$item/g);
                substr($_, $i) = $tail if $n;
                return $n;
            },
        ],
    },
    {
        # En presentaciones, "png" está en una lista de formatos extra que
        # exige window.extraExportFormats (no existe en la app móvil y la
        # comprobación fallaría). Se permite png en la app.
        desc   => 'Menú: permitir PNG en presentaciones de la app',
        marker => 'adk:png-extra',
        try    => [ sub {
            s/!window\.extraExportFormats\.includes\(/!(window.ThisIsAMobileApp && format === 'png') \/* adk:png-extra *\/ && !(window.extraExportFormats || []).includes(/
        } ],
    },
    {
        # Disponible también en modo solo lectura (exportar sin editar).
        desc   => 'Menú: PNG permitido en solo lectura',
        marker => "'downloadas-png', /* adk:png-readonly */",
        try    => [
            sub {
                s/('downloadas-ods', 'downloadas-xls', 'downloadas-xlsx', 'downloadas-csv',)/'downloadas-png', \/* adk:png-readonly *\/ $1/
            },
            sub {
                s/(allowedViewModeActions: \[[ \t]*\n([ \t]*))/$1'downloadas-png', \/* adk:png-readonly *\/\n$2/
            },
        ],
    },
);
