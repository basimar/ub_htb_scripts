#!/usr/bin/perl -w

# add-geographica-to-descriptors.pl
#
# input: 
#   ../from_swasd/swafv-descriptors.txt
#   Hierarchie ohne Geographica
#
#   ../tmp/desk-geographica.txt
#   Deskriptoren mit Geographica
#
# output:
#   ../tmp/swafv-descriptors-plus.txt
#   Hierarchie mit Geographica
#
#   ../tmp/geographisca.tmp
#   Konkordanz Deskriptor mit Geographicum <-> Detailseiten-ID
#
# history
#   14.08.2014 andres.vonarx@unibas.ch
#

use strict;
use FindBin;

my $InputDesk   = $FindBin::Bin ."/../from_swasd/swafv-descriptors.txt";
my $OutputDesk  = $FindBin::Bin ."/../tmp/swafv-descriptors-plus.txt";
my $InputGeo    = $FindBin::Bin ."/../tmp/desk-geographica.txt";
my $OutputGeo   = $FindBin::Bin ."/../tmp/geographica.tmp";


# (1)
# -- ermittle die letzten IDs für Deskriptoren und TreeMenu-Items
# -- aus der Hierarchie ohne Geographica
my $did=0;
my $mid=0;
open(DIN, "<$InputDesk")
    or die("cannot read $InputDesk: $!");
while ( <DIN> ) {
    /did(\d+)°°°(\d+)$/;
    my $d = $1;
    my $m = $2;
    $d ||= 0;
    $m ||= 0;
    $did = ( $did < $d ) ? $d : $did;
    $mid = ( $mid < $m ) ? $m : $mid;
}
close DIN;


# (2)
# - sammle die Information zu Geographischen Unterfeldern in Deskriptoren,
# - generiere die zusätzlichen IDs für Unterseiten und TreeMenu-Items,
# - schreibe eine Lookup-Tabelle
# 
my $lookup;
open(GIN,   "<$InputGeo") 
    or die("cannot read $InputGeo: $!");
open(GOUT,  ">$OutputGeo") 
    or die("cannot write $OutputGeo: $!");
while ( <GIN> ) {
    chomp;
    /(.*)\$\$z(.*)/;
    my $desk = $1;
    my $geo = $2;
    # die originelle SWA-Sortierung der Geographika:
    my $sort;
    if ( $geo eq 'Schweiz' ) {
        $sort = 1;
    } elsif ( $geo eq 'Deutsche Schweiz' || $geo eq 'Romandie, Tessin' ) {
        $sort = 2;
    } else {
        $sort = 3;
    }
    $sort .= $geo;
    $did++;
    $mid++;
    $lookup->{$desk}->{$sort} = {
            geo => $geo,
            did => $did,
            mid => $mid
        };
    
    print GOUT qq/$_|did$did\n/;
}
close GIN;
close GOUT;

# (3) 
# schreibe die erweiterte Hierarchie der Deskriptoren
open(DIN, "<$InputDesk")
    or die("cannot read $InputDesk: $!");
open(DOUT, ">$OutputDesk")
    or die("cannot write $OutputDesk: $!");
while ( <DIN> ) {
    /^\s+(.*) > (.*)$/;
    my $desk = $1;
    my $key = $2;
    $key |= '';
    print DOUT $_;
    if ( $key =~ /^did/ and $lookup->{$desk} ) {
        foreach my $key ( sort keys %{$lookup->{$desk}} ) {
            my $thingy = $lookup->{$desk}->{$key};
            print DOUT '   ' .$thingy->{geo} .' > did' .$thingy->{did} .'°°°' .$thingy->{mid} ."\n";
        }
    }
}    
close DIN;
close DOUT;
