#!/usr/bin/perl

# in:   tmp/indexterms.tx, sortierte Liste der Indexbegriffe, mit Dubletten
# out:  output/index-[a-z].html
#
# History
#   20.08.2010: rewrite / andres.vonarx@unibas.ch
#   18.08.2014: fix for non-alpha page

use strict;
use ava::sort::utf8;

my $infile   = 'tmp/indexterms.txt';
my $template = 'output/template-index.html';
my $outdir   = 'output';

my $AZBAR_TAG = qq|<div id="indexaz" class="botnavi">|;
my $LISTE_TAG = qq|<div id="result">|;


# -- Template einlesen
open(IN,"<$template") or die("cannot read $template: $!");
{ local $/; $_ = <IN>; }
close IN;
my $Template=$_;

# -- vorhandene Buchstaben (= Indexseiten) ermitteln
my %Page;
open(IN,"<$infile") or die("cannot read $infile: $!");
while ( <IN> ) {
    my $char = get_1st_char($_);
    $Page{$char}=1;
}
close IN;


# -- Seiten erstellen
my($prevchar,$liste);
open(IN,"<$infile") or die("cannot read $infile: $!");
while ( <IN> ) {
    chomp;
    my $char = get_1st_char($_);
    if ( $char ne $prevchar ) {
        printpage($prevchar,\$liste);
        $prevchar=$char;
        $liste=qq|$LISTE_TAG\n|;
    }
    my($term,$siehe,$did)=split /#/;
    if ( $term eq $siehe ) {
        $siehe = '';
    }
    $term=safe_xml($term);
    if ( $siehe ) {
        $siehe=safe_xml($siehe);
        $liste .= qq|<p>$term <a href="javascript:jump('$did')">$siehe</a></p>\n|;
    } else {
        $liste .= qq|<p><a href="javascript:jump('$did')">$term</a></p>\n|;
    }
}
printpage($prevchar,\$liste);
close IN;

sub printpage {
    my($char,$ref)=@_;
    return unless ( $$ref );
    my $az = azbar($char);
    local $_ = $Template;
    s|$AZBAR_TAG.*?</div>|$az|gs;
    s|$LISTE_TAG.*?</div>|$$ref</div>|s;
    my $outfile = $outdir .'/index-' .lc($char) .'.html';
    open(OUT,">$outfile") or die("cannot write $outfile: $!");
    print OUT $_;
    close OUT;
}

sub azbar {
    my $curr=shift;
    my $bar=qq|$AZBAR_TAG\n|;
    for my $char ( '0', 'A' .. 'Z' ) {
        my $lchar = lc($char);
        if ( $char eq $curr ) {
            $bar .= qq|<span class="az_current">&#160;$char&#160;</span>\n|;
        } else {
            if ( $Page{$char} ) {
                $bar .= qq|<a class="index" href="index-$lchar.html">$char</a>&#160;\n|;
            } else {
                $bar .= qq|<span class="az_na">$char</span>&#160;\n|;
            }
        }
    }
    $bar .= '</div>';
}

sub get_1st_char {
    my $line = shift;
    my $char = substr(utf8sort_uc($line),0,1);
    if ( $char !~ /[A-Z]/ ) {
        $char = "0";
    }
    $char;
}

sub safe_xml {
    local $_=shift;
    s|&|&amp;|g;
    s|<|&lt;|g;
    s|>|&gt;|g;
    s|"|&quot;|g;
    s|'|&apos;|g;
    $_;
}
