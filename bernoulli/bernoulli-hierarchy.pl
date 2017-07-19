#!/usr/bin/perl

# input:  Textfile (sortierte Liste von Briefwechsel/Korrespondexz)
# output: XML (Hierarchie der Bernoulli Briefwechsel und Korrespondenten)

use strict;
use ava::sort::utf8;

my $infile=shift @ARGV || die "usage: $0 <infile>";

my $last;
open(IN,"<$infile") or die "cannot read $infile: $!";
my $date=localtime();
print<<EOD;
<?xml version="1.0" encoding="utf-8"?>
<bernoulli_tree generated="$date">
EOD

while ( <IN> ) {
    chomp;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/\"/&quot;/g;

    my($bw,$korr)=split(/\t/);
    next unless ($bw && $korr);
    if ($bw ne $last ) {
    if ( $last ) {
            print "</briefwechsel>\n";
        }
        print qq|<briefwechsel von="$bw">\n|;
        $last=$bw;
    }
    # generate an ASCII 7 Name Form for Links to Aleph
    my $asc=$korr;
    $asc=~ s/&\w+;//g;
    $asc=utf8sort_lc($asc);
    $asc=~ s/^\s+//;
    $asc=~ s/\s+$//;
    $asc=~ s/  +/ /g;
    $asc=ucfirst($asc);
    $asc=~ s/ (.)/' ' .uc($1)/eg;

    print qq|<korr ascii7="$asc">$korr</korr>\n|;
}
print<<EOD;
</briefwechsel>
</bernoulli_tree>
EOD

