#!/usr/local/bin/perl -w

# swasd-splitte-detailseiten.pl
#	splitte die globale html-seite mit vollanzeigen in
#	einzelne seiten.
#
# in:  tmp/detailseiten.html
# out: output/details/did*.html
#
# history:
# 	18.08.2010 andres.vonarx@unibas.ch

use strict;

my $infile   = 'tmp/detailseiten.html';
my $template = 'output/template-details.html';
my $outdir   = 'output/details/';

# -- store template into $Template
my $Template;
open(T,"<$template") or die("cannot read $template: $!");
{ local $/; $Template = <T>; }
close T;

# -- parse global html file
open(IN,"<$infile") or die("cannot read $infile: $!");
my $did;
my $content='';
my $descriptor='';
my $synonyme='';
while ( <IN> ) {
    if ( /^<h1>(did\d+)/ ) {
        write_page($did,$descriptor,\$synonyme,\$content);
        $did = $1;
        $content = '';
        $descriptor = '';
        $synonyme = '';
        next;
    }
    if ( m|^<h2>(.*)</h2>| ) {
        $descriptor = $1;
        next;
    }
    if ( m|<h3>| ) {
        while ( 1 ) {
            $_ = <IN>;
            if ( m|</h3>| ) {
                last;
            } else {
                $synonyme .= $_;
            }
        }
        next;
    }
    $content .= $_;
}
write_page($did,$descriptor,\$synonyme,\$content);
close IN;

sub write_page {
    my($did,$descriptor,$synonyme,$content)=@_;
    return unless ( $did );
    my $outfile =  qq|$outdir$did.html|;
    local $_ = $Template;
    s/%%DESCRIPTOR%%/$descriptor/g;
    s/%%CONTENT%%/$$content/;
    s/%%SYNONYME%%/$$synonyme/;
    open(OUT, ">$outfile") or die("cannot write $outfile: $!");
    print OUT $_;
    close OUT;
}
