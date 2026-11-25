#!/usr/bin/env perl
# Aplica una lista de parches de texto a un archivo, de forma idempotente.
#
# Uso: perl apply.pl <definiciones.pl> <archivo>
#
# <definiciones.pl> devuelve una lista de hashes:
#   { desc => 'texto', marker => 'cadena que indica que ya se aplicó',
#     try => [ sub { s/.../.../ }, sub { ... } ] }   # alternativas en orden
# Cada sub recibe el contenido en $_ y devuelve el número de reemplazos.
# Sale con código 0 siempre; los parches que no apliquen se avisan con
# "[aviso]" para no romper el build cuando upstream cambia.
# MPL-2.0
use strict;
use warnings;

my ($defs_file, $target) = @ARGV;
die "uso: apply.pl <definiciones> <archivo>\n" unless $defs_file && $target;

my @patches = do $defs_file;
die "no se pudieron leer $defs_file: $@ $!\n" unless @patches;

open my $in, '<:raw', $target or do {
    print STDERR "\e[1;33m[aviso] no existe $target\e[0m\n";
    exit 0;
};
local $/;
my $text = <$in>;
close $in;

my $changed = 0;
for my $p (@patches) {
    if (index($text, $p->{marker}) >= 0) {
        print "  ✓ $p->{desc} (ya aplicado)\n";
        next;
    }
    my $done = 0;
    for my $alt (@{ $p->{try} }) {
        local $_ = $text;
        my $n = $alt->();
        if ($n && index($_, $p->{marker}) >= 0) {
            $text = $_;
            $done = 1;
            last;
        }
    }
    if ($done) {
        print "  ✓ $p->{desc}\n";
        $changed = 1;
    } else {
        print STDERR "\e[1;33m[aviso] $p->{desc}: no se encontró el patrón en $target\e[0m\n";
    }
}

if ($changed) {
    open my $out, '>:raw', $target or die "no se puede escribir $target: $!\n";
    print $out $text;
    close $out;
}
