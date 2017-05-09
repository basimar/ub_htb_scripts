#!/usr/bin/perl

# Generiert eine HTML-Indexseite aus einer Textliste.
# Ersetzt dabei die vorhandene Liste in der Original-HTML-Datei.
# *** VERSION FUER ROBOTS ***
# 25.08.2008 / ava

use strict;
use Getopt::Long;
use URI::Escape;

my $FORMAT='long';    # Link auf CGI-Skript
#my $FORMAT='short';  # nur Name

sub usage {
    print<<EOD;
usage: $0 --infile=<file> --outfile=<file> --code=code

options:
--infile    Textfile, generiert mit hierarchie_zu_text.xsl
--outfile   HTML-Seite (wird überschrieben)
EOD
    exit;
}

my($infile,$outfile);
GetOptions (
    "infile=s"  => \$infile,
    "outfile=s" => \$outfile,
    ) or usage;

( $infile ) or usage;
( $outfile) or usage;

# -- Liste generieren
my $LISTE=qq|<!-- START LISTE -->\n|;
my $last_char='';
open(IN,"<$infile") or die("cannot read $infile: $!");
while ( <IN> ) {
    chomp;
    s/\t.*$//;
    $LISTE .= format_zeile($_);
}
close IN;
$LISTE .= qq|<!-- ENDE LISTE -->|;

open(IN,"<$outfile") or die("cannot read $outfile: $!");
{local $/; $_ = <IN>; }
close IN;
s|<!-- START LISTE -->.*<!-- ENDE? LISTE -->|$LISTE|s;
open(OUT,">$outfile") or die("cannot write $outfile: $!");
print OUT $_;
close OUT;

sub format_zeile {
    local $_=shift;
    my $display=$_;
    $display =~ s/>/&gt;/g;
    $display =~ s/</&gt;/g;
    my $ret;
    if ( $FORMAT eq 'long' ) {
        my $name=uri_escape($_);
        my $archiv = ( $outfile =~ /person/ ) ?   'p' :
                     ( $outfile =~ /koerper/ ) ?  'k' :
                     ( $outfile =~ /autograph/) ? 'a' :
                     die("he?");
        $ret = qq|<p><a href="detail/$archiv/$name/"><b>$display</b></a></p>\n|;
    } elsif ( $FORMAT eq 'short' ) {
        $ret =qq|<p>Nachlass/Privatarchiv: <b>$display</b></p>\n|;
    } else {
        die ("he??");
    }
    $ret;
}