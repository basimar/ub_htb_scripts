#!/usr/bin/perl

# generiere den Index fuer die CGI-Suchmaschine (ava::search::index)
# (Körperschaften)
#
# Input:
#   kss-aut.txt
#       alphabetische Liste der Körperschaften (normalisiert) | GND-Nummer
#   Beispiel:
#       Aachener Rückversicherungs-Gesellschaft|(DE-588)1085251004
#
# Output:
#   Textdatei 
#       GND (ohne Präfix '(DE-588)' | Anzeige | Aleph-Key | nochmals Aleph-Key (für die Suche)
#   Beispiel:
#       1085251004|Aachener Rückversicherungs-Gesellschaft|aachener rueckversicherungs gesellschaft|aachener rueckversicherungs gesellschaft
#
# History;
#   rev. 07.04.2016 andres.vonarx@unibas.ch

use FindBin;
use ava::sort::utf8;
use strict;

my $infile  = $FindBin::Bin .'/../tmp/kss-aut.txt';
my $outfile = $FindBin::Bin .'/../tmp/index_swafv_kss';

open(IN,"<$infile") or die("cannot read $infile: $!");
open(OUT,">$outfile") or die("cannot write $outfile: $!");
while ( <IN> ) {
    chomp;
    my($kss,$gnd) = split /\|/;
    $kss =~ s/<</[/;
    $kss =~ s/>>/]/;
    $gnd =~ s/\(DE\-588\)//;
    my $key=aleph_escape($kss);
    print OUT qq{$gnd|$kss|$key|$key\n};
}

sub aleph_escape {
    local $_ = shift or return '';
    $_ = ava::sort::utf8::utf8sort_lc($_);
    # remove nonsorting leading article
    s/<<.*>> ?//;
    # normalize blanks
    s/  +/ /g;
    s/^\s+//;
    s/\s+$//;
    $_;
}    
