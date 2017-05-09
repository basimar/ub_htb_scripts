#!/usr/bin/perl

# Generiert eine HTML-Indexseite aus einer Textliste.
# Ersetzt dabei die vorhandene Liste in der Original-HTML-Datei.
# 27.03.2008/ava

use strict;
use Getopt::Long;
use ava::sort::utf8;

my $START_AZ_LEISTE = '<li class="az">';
my $ENDE_AZ_LEISTE = '</li>';
my $AZ_SPACER = '&#x00B7;';  # U+00B7   MIDDLE DOT
my $AZ_TOP = '&#x2191;';     # U+2191  UPWARDS ARROW
sub usage {
    print<<EOD;
usage: $0 --infile=<file> --outfile=<file> --az=<ja|nein>

options:
--infile    Textfile, generiert mit hierarchie_zu_text.xsl
--outfile   HTML-Seite (wird überschrieben)
--az        A-Z Navigationshilfe einbauen
EOD
    exit;
}

my($infile,$outfile,$az);
GetOptions (
    "infile=s"  => \$infile,
    "outfile=s" => \$outfile,
    "az"        => \$az
    ) or usage;

( $infile ) or usage;
( $outfile) or usage;

# -- Liste generieren
my $LISTE=qq|<!-- START LISTE -->\n|;
my $last_char='';
open(IN,"<$infile") or die("cannot read $infile: $!");
while ( <IN> ) {
    chomp;
    my $current_char = substr(utf8sort_uc($_),0,1);
    if ( $az and $current_char ne $last_char ) {
        $LISTE .= az_leiste($current_char);
        $last_char=$current_char;
    }
    $LISTE .= zeile($_);
}
close IN;
$LISTE .= qq|<!-- ENDE LISTE -->|;

# -- Originale Datei einlesen
open(IN,"<$outfile") or die("cannot read $outfile: $!");
{local $/; $_ = <IN>; }
close IN;
s|<!-- START LISTE -->.*<!-- ENDE? LISTE -->|$LISTE|s;

# -- Seite schreiben
open(OUT,">$outfile") or die("cannot write $outfile: $!");
print OUT $_;
close OUT;


sub zeile {
    local $_ = shift;
    my $ret='<li>';
    my($title,$recno,$hierarchy) = split /\t/;
    $title =~ s/>/&gt;/g;
    $title =~ s/</&lt;/g;
    if ( $hierarchy eq '+' ) {
        $ret .= qq|<a href="javascript:openTop('d$recno.html')"><img alt="[+]" src="icons/plus0.gif" border="0" hspace="10"></a>|;
    } else {
        $ret .= qq|<img alt="" src="icons/empty0.gif" border="0" hspace="10">|;
    }
    $ret .= qq|<a href="javascript:bib('$recno')">$title</a>\n|;
}

sub az_leiste {
    my $current = shift;
    my $ret=qq|$START_AZ_LEISTE<a name="$current"></a>&nbsp;&nbsp;|;
    #$ret .= qq|<a href="javascript:window.scrollTo(0,0)">&nbsp;$AZ_TOP&nbsp;</a>$AZ_SPACER|;
    for my $char ( 'A' .. 'Z' ) {
        if ( $char eq $current ) {
            $ret .= qq(<span class="azcurr">&nbsp;$char&nbsp;</span>$AZ_SPACER);
        } else {
            $ret .= qq(<a href="#$char">&nbsp;$char&nbsp;</a>$AZ_SPACER);
        }
    }
    $ret .= qq|<a href="javascript:window.scrollTo(0,0)">&nbsp;$AZ_TOP&nbsp;</a>|;
    $ret .= qq|$ENDE_AZ_LEISTE\n|;
}

