#!/usr/bin/perl

# verschlanke den Index fuer die CGI-Suchmaschine (ava::search::index)
# (Deskriptoren-Index)
#
# 20.05.2014 andres.vonarx@unibas.ch

use strict;
use FindBin;

my $infile  = $FindBin::Bin .'/../from_swasd/suchmaschine_deskriptoren.tmp';
my $outfile = $FindBin::Bin .'/../tmp/index_swafv_desk';

open(IN,"<$infile") or die("cannot read $infile: $!");
open(OUT,">$outfile") or die("cannot write $outfile: $!");
while ( <IN> ) {
    chomp;
    my @a = split /\|/;
    $_ = pop @a;
    my @b = split /°°°/;
    my %b = map {$_=>1} @b;
    print OUT join('|',@a,join(' ', sort keys %b)),"\n";
}
