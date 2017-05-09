#!/usr/bin/perl

# Baue den Baum um: Toplevel raus + DOIs rein.

use strict;
use FindBin;

my $infile  = $FindBin::Bin . '/tmp/tree_tmp.js';
my $outfile = $FindBin::Bin . '/tmp/tree_items.js';
my $doilist = get_dois();

open(IN,"<$infile") or die "cannot read $infile: $!";
open(OUT,">$outfile")or die "cannot write to $outfile: $!";

while (<IN>) {
	
	# 1. ueberfluessige Zeile raus
	if ( /000005411/ ) { next; }
	elsif ( /^\t\]/ ) { next; }
	# 2. dois finden und einfuegen
	elsif ( /'(\d{9})/) {
		my $sysno = $1;
		if ( $doilist->{$sysno} ) {
			s/'\d{9}/'$doilist->{$sysno}/;
			s/javascript:bib/javascript:doi/;
		}
	}
	# 3. Titel anders formatieren:
	s/'39 : Abbildungssammlung/'NL 13 : 39 : Abbildungssammlung/;
	
	print OUT $_;	
}

close IN;
close OUT;

sub get_dois {
	my $ret;
	my $doifile = $FindBin::Bin . '/tmp/doi.txt';
	
	open(F,"<$doifile") or die "cannot read $doifile: $!";
	
	while (<F>) {
			chomp;
			my($url,$sys) = split(/\t/);
			# wir haben auch noch andere URLs. Wir nehmen nur die DOIs.
			if ( $url =~ m|^http://dx\.doi\.org/(10.7891/e-manuscripta-\d+)| ) {
				$ret->{$sys} = $1;
			}
	}
	close F;
	
	return $ret;
}
