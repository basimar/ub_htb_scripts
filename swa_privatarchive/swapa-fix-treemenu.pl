#!/usr/bin/perl

# definiere Icons und CSS-Styles fuer nicht-aktive Menu-Items
# 30.08.2010/andres.vonarx@unibas.ch

use strict;

my $file='tmp/tree_items.js';

#  0: leere Ordner werden versteckt;
#  1: leere Ordner werden als nicht-aktive gezeigt

my $show_empty_folders = 1;

my $na_in = qr|\'javascript\:swapa\(\\\'000\\\'\)\'|;
my $na_out = qq|'',{'i0':'icons/foldergray.gif','i4':'icons/foldergray.gif','i64':'icons/foldergray.gif', 'i68':'icons/foldergray.gif','s0':'na','s4':'na','s64':'na','s68':'na'}|;

my $txt;
open(F,"<$file") or die("cannot read $file: $!");
while ( <F> ) {
    if ( $show_empty_folders ) {
        s|$na_in|$na_out|e;
    } else {
        next if ( m|$na_in|);
    }
    $txt .= $_;
}
close F;
open(F,">$file") or die("cannot write $file: $!");
print F $txt;
close F;

