#!/usr/bin/perl

# extract-firmen-deskriptoren.pl
#
# input:
#   swa-doksf.seq    
#   Aleph Sequential mit SWA Firmen + Verbänden
#
# output:
#   kss-desk.tmp   
#   Konkordanz Deskriptor (690FC) <-> Firma/Verband (110/111/710/711) | GND
#       Deskriptor: enthält $$z für Geographicum
#       Firma: enthält Displayform und GND-Nummer, Artikel in <<>>
#   unsortiert, dublett 
#
# history:
#   05.06.2014  V.2, andres.vonarx@unibas.ch
#   14.08.2014  690FC $z wird auch ausgegeben (geograph. Unterteilung)
#   18.08.2014  bugfix in Initialisierung von $record / ava
#   29.03.2016  uebergangszeit GND / ava

use Data::Dumper; $Data::Dumper::Indent=1; $Data::Dumper::Sortkeys=1;
use FindBin;
use strict;

my %KSS_MIT_GND  = map { $_ => 1} ('1101','1102','1111','1112','7101','7102','7111','7112');
my %KSS_OHNE_GND = map { $_ => 1} ('710','711');

my $TempDir     = "$FindBin::Bin/../tmp/";
my $InFile      = $TempDir .'swa-doksf.seq';
my $OutFile     = $TempDir .'kss-desk.tmp';

my $old_sysno;
my $record;

open(IN,"<$InFile") 
    or die("cannot read $InFile: $!");
open(OUT,">$OutFile")
    or die("cannot write $OutFile: $!");
while ( <IN> ) {
    chomp;
    my $sysno = substr($_,0, 9);
    if ( $sysno ne $old_sysno ) {
        print_record();
        $old_sysno = $sysno;
        $record={};
    }
    my $field = trim(substr($_,10,6));
    $_ = substr($_,21);   # entferne Sysno, Feldtag, '$$a'
    
    if ( $KSS_MIT_GND{$field} ) {
        # entferne $$4
        s/\$\$4.*$//;
        # entferne $$e (Funktionsbezeichnung), aber nur wenn es *nach* $$1 kommt
        #   Beispiel: Caisse Nationale de Crédit Agricole$$gParis$$1(DE-588)36717-5$$eVerfasser$$4aut
        # ... aber nicht, wenn es *vor* $$1 kommt:
        #   Beispiel: Textile Institute$$gManchester$$eConference$$1(DE-588)1091742138
        s/(\$\$1.*)\$\$e.*$/$1/;
        s/\$\$1(.*)$//;
        my $GND=$1;
        $_ = display_kss($_);
        $record->{kss}->{"$_|$GND"} = 1;
    } 
    elsif ( $KSS_OHNE_GND{$field} ) {
        s/\$\$1.*$//;         # fehlerhafte GND-Nummer entfernen
        $_ = display_kss($_);
        $record->{kss}->{"$_|0"} = 1;
    } 
    elsif ( $field eq '690FC' ) {
        s/\$\$2SWA.*$//;
        $record->{desk}->{$_} = 1;
    }
}
close IN;
close OUT;

sub print_record {
    return unless ( $record );
    return unless ( $record->{desk} );
    return unless ( $record->{kss} );
    foreach my $desk ( keys %{$record->{desk}} ) {
        foreach my $kss ( keys %{$record->{kss}} ) {
            print OUT "$desk|$kss\n";
        }
    }
}

sub display_kss {
    local $_ = shift;
    # Geographische Ordnungshilfe in Klammern:
    s/\$\$g(.*?)\$/ ($1)\$/;
    s/\$\$g(.*?)$/ ($1)/;
    s/\$\$./. /g;
    $_;
}

sub trim {
    local $_=shift;
    s/^\s+//;
    s/\s+$//;
    $_;
}
