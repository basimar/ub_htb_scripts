#!/usr/bin/perl

use strict;
use Getopt::Long;

sub usage {
    print<<EOD;
usage: $0 [options]

options
--infile     input file, generiert mit tigra_tree_menu_split.xsl (obligatorisch)
--outdir     Ausgabeverzeichnis für HTML- und JS-Seiten (obligatorisch)
--template   Template für HTML-Seiten (obligatorisch)
--backlink   Dateiname für "zurück" Link (obligatorisch)
--quiet      keine Meldungen
EOD
    exit;
}
my($infile,$outdir,$template,$backlink,$quiet);
GetOptions (
    "infile=s"  => \$infile,
    "outdir=s"  => \$outdir,
    "template=s"=> \$template,
    "backlink=s"=> \$backlink,
    "quiet"     => \$quiet
    ) or usage;
( $infile ) or usage;
( $outdir ) or usage;
( $backlink ) or usage;
( $template ) or usage;

my $Template;
open(IN,"<$template") or die("cannot read $template: $!");
{ local $/; $Template = <IN>; }
close IN;

my($Recno,$JSCode);
open(IN,"<$infile") or die("cannot read $infile: $!");
while ( <IN> ) {
    if ( s/^===// && s/\D//g ) {
        print_pages();
        $Recno = $_;
        next;
    }
    $JSCode .= $_;
}
close IN;
print_pages();

sub print_pages {
    return unless ( $Recno );
    return unless ( $JSCode );

    # -- HTML-File
    my $html_file = qq/d$Recno.html/;

    local $_ = $Template;
    s/%%JSCode%%/$JSCode/g;
    s/%%BACKLINK%%/$backlink/g;

    open(OUT,">$outdir/$html_file") or die("cannot write $outdir/$html_file: $!");
    print OUT $_;
    close OUT;

    $JSCode='';
}
