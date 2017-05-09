#!/usr/bin/perl

# luzern-treemenus.pl
# mache je eine Tree-Menu JS Datei fuer alle Toplevel-Aufnahmen,
# die verknüpfte Detailseiten haben.
#
# History
# 10.09.2010 - andres.vonarx@unibas.ch

use strict;
use FindBin;
use ava::sort::utf8;

my $output_dir      = 'output';
my $infile          = 'tmp/toplevel.tmp';
my $marcfile        = 'tmp/luzern-marc.xml';
my $link490file     = 'tmp/luzern.490';
my $tmp_hierarchie  = 'tmp/hierarchie.xml';
my $verbose         = 1;

chdir $FindBin::Bin;

open(IN,"<$infile") or die("cannot read $infile: $!");
while ( <IN> ) {
    chomp;
    my($sysno,$text,$details,undef) = split /\|/;
    next if ( $details ne 'ja' );

    # mache einen Dateinamen aus dem Namen des Aktenbildners
    # (nur Kleinbuchstaben, keine Sonderzeichen, keine Spatien)
    my $outfile = $text;
    $outfile =~ s/ *\(.*$//;
    $outfile = utf8sort_lc($outfile);
    $outfile =~ s/  */_/g;
    $outfile = qq|tree_$outfile.js|;
    ( $verbose ) and print qq|- $text -> $outfile\n|;
    $outfile = 'output/' .$outfile;

    open(F,">tmp/top_sysno") or die("cannot write tmp/top_sysno: $!");
    print F $sysno, "\n";
    close F;

    my $cmd = qq|perl ../htb/htb_build_hierarchy_top_down|
        .qq| --toplist=tmp/top_sysno|
        .qq| --list490=tmp/luzern.490|
        .qq| --outfile=tmp/hierarchie.xml|
        ;
    system $cmd;

    $cmd = qq|saxon -o $outfile tmp/hierarchie.xml ../htb/tigra_tree_menu.xsl|
        .qq| MARCXML=$FindBin::Bin/tmp/luzern-marc.xml|
        .qq| ROOTNODE=0|
        .qq| JS_CMD='hanopen'|
        ;
    system $cmd;

    # -- korrigiere Zeichensatz
    open(F,"<$outfile") or die("cannot read $outfile: $!");
    { local $/; $_ = <F>; }
    close F;
    s/<<//g;
    s/>>//g;
    open(F,">$outfile") or die("cannot write $outfile: $!");
    print F $_;
    close F;
}
close IN;
