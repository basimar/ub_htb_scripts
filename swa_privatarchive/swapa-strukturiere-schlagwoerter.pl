#!/usr/bin/perl

use ava::sort::utf8;
use strict;
use Data::Dumper; $Data::Dumper::Sortkeys=1;
use Text::CSV;

use utf8;
binmode STDOUT, ":utf8";

my $infile  = 'swapa-dsv05-oberbegriffe-schlagwoerter.csv';
my $outfile = 'tmp/swapa-schlagwoerter.xml';
my $SEP = '#';

my $csv = Text::CSV->new({
     'quote_char'  => '"',
     'escape_char' => '"',
     'sep_char'    => ',',
     'binary'      => 1
 });
open(IN,"<$infile") or die("cannot read $infile: $!");
open(OUT,">$outfile") or die("cannot write $outfile: $!");
my $h;
while ( my $ar = $csv->getline( *IN ) ) {
    next if ( $ar->[0] =~ /^#/ );  # Kommentarzeilen
    next unless ( $ar->[1] );
    if ( $ar->[2] ) {
        $h->{$ar->[1]}->{$ar->[2]} = $ar->[0];
    } else {
        $h->{$ar->[1]} = $ar->[0];
    }
}

print OUT qq|<?xml version="1.0" encoding="UTF-8"?>\n|
    .qq|<!-- generiert mit $0 -->\n|
    .qq|<swa_privatarchive_schlagwoerter>\n|;
foreach my $top ( sort utf8sort keys %$h ) {
    my $xtop = safe_xml($top);
    if ( ref($h->{$top}) ) {
        # Top-Element hat Unterelemente
        print OUT qq| <top name="$xtop">\n|;
        foreach my $sub ( sort utf8sort keys %{$h->{$top}} ) {
            my $xsub = safe_xml($sub);
            my $desk = safe_xml($h->{$top}->{$sub});
            print OUT qq|  <sub name="$xsub" deskriptor="$desk" />\n|;
        }

    } else {
        # Topelement hat keine Unterelemente
        my $desk = safe_xml($h->{$top});
        print OUT qq|<top name="$xtop" deskriptor="$desk">\n|;
    }
    print OUT qq| </top>\n|;
}
print OUT qq|</swa_privatarchive_schlagwoerter>\n|;

sub safe_xml {
    local $_ = shift;
    s/&/&amp;/g;
    s/>/&gt;/g;
    s/</&lt;/g;
    s/"/&quot;/g;
    s/'/&apos;/g;
    $_;
}

