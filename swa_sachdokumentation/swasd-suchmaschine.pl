#!/usr/bin/perl

# verschlanke den Index fuer die CGI-Suchmaschine (ava::search::index)
#
# History
# 20.08.2010 rewrite / andres.vonarx@unibas.ch

use strict;

my $infile  = 'tmp/suchmaschine.tmp';
my $outfile = 'tmp/suchmaschine.txt';

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
