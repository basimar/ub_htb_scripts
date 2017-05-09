#!/usr/bin/perl -w

# swafv-splitte-detailseiten.pl
#   Splittet die provisorische Seite "detailseiten.html" in einzelne 
#   Seiten und reichert sie mit den passenden Koerperschaften an.
#   Berücksichtigt auch zusätzliche geographische Unterseiten

# history:
#   19.05.2014 andres.vonarx@unibas.ch
#   18.08.2014 gegraphische Unterseiten, Sortierung / ava
#   07.04.2016 Anpassung an GND / ava
#   20.05.2016 bessere Performance durch in-memory lookup von InputKss / ava
#   29.06.2016 fixe lookup von Geographice / ava

use strict;
use ava::sort::utf8;
use FindBin;

my $SIEHE_GEO = 'Siehe unter den einzelnen Regionen.';
my $KEINE_KSS = 'Es sind noch keine Dokumente im Katalog nachgewiesen.';
my $Verbose   = 0;

my $InputContext    = $FindBin::Bin ."/../from_swasd/detailseiten.html";
my $InputKss        = $FindBin::Bin ."/../tmp/kss-desk.txt";
my $TemplateFile    = $FindBin::Bin ."/../output/template-details.html";
my $OutDir          = $FindBin::Bin ."/../output/details/";
my $GeoFile         = $FindBin::Bin ."/../tmp/geographica.tmp";


# -- store template into $Template
my $Template;
open(T,"<$TemplateFile") or die("cannot read $TemplateFile: $!");
{ local $/; $Template = <T>; }
close T;

# -- make a lookup table for Geographica
my $Geo;
open(GEO,"<$GeoFile") or die("cannot read $GeoFile: $!");
while ( <GEO> ) {
    chomp;
    my($tmp,$did) = split /\|/;
    $_ = $tmp;
    my($desk,$geo) = split /\$\$z/;
    $Geo->{$desk}->{$geo} = $did;
}
close GEO;

# -- make a lookup table for descriptors/firms
open(DESC,"<$InputKss") or die("cannot read $InputKss: $!");
my @Descriptors = <DESC>;
close DESC;

# -- parse global html file
open(IN,"<$InputContext") or die("cannot read $InputContext: $!");
my $did;
my $context='';
my $descriptor='';
while ( <IN> ) {
    if ( /^<h1>(did\d+)/ ) {
        do_descriptor($did,$descriptor,$context);
        $did = $1;
        $context = '';
        $descriptor='';
        next;
    }
    if ( m|^<h2>(.*)</h2>| ) {
        $descriptor = $1;
        next;
    }
    s|<br><br/>|<br />|g;
    $context .= $_;
}
do_descriptor($did,$descriptor,$context);
close IN;

sub do_descriptor {
    # -- prüfe für alle Deskriptoren, ob sie allfällige geographische
    # -- Unterteilungen habe; mache für diese eine separate Unterseite
    # -- mit eigener ID und eigener KSS-Liste, aber mit demselben
    # -- Kontext
    my($did,$descriptor,$context)=@_;
    return unless ( $did );
    my $liste;
    if ( $Geo->{$descriptor} ) {
        $liste = make_kss_liste($descriptor);
        # Deskriptor pur
        if ( $liste eq '' ) {
            $liste = qq|<p class="comment">$SIEHE_GEO</p>\n|;
            write_page($descriptor,$did,$context,$liste);
        } else {
            write_page($descriptor,$did,$context,$liste);
        }
        # Deskriptoren mit Geographikum
        foreach my $geo ( keys %{$Geo->{$descriptor}} ) {
            $liste = make_kss_liste($descriptor ."\$\$z" .$geo);
            my $titel = $descriptor .'. ' .$geo;
            $did = $Geo->{$descriptor}->{$geo};
            write_page($titel,$did,$context,$liste);
        }
        
    } else {
        # Deskriptor pur
        $liste = make_kss_liste($descriptor);
        $liste ||= qq|<p class="comment">$KEINE_KSS</p>\n|;
        write_page($descriptor,$did,$context,$liste);
    }
}
sub kss_sort {
    my $aa = $a;
    my $bb = $b;
    $aa =~ s/<<.*>> ?//;
    $bb =~ s/<<.*>> ?//;
    utf8sort_lc($aa) cmp utf8sort_lc($bb);
}

sub make_kss_liste {
    # -- extrahiere die Zeilen mit dem gewünschten Deskriptor
    # -- aus der Konkordanzliste Deskriptor <-> Köperschaft,
    # -- sortiere die Liste und formatiere die Einträge.
    my $deskriptor=quotemeta(shift);
    my $ret='';
    my @lines = grep { /^$deskriptor\|/ } @Descriptors;
    if ( @lines ) {
        @lines = sort kss_sort @lines;
        while ( @lines ) {
            my $line = shift @lines;
            chomp $line;
            my(undef, $ks, $gnd ) = split(/\|/, $line);
            $gnd =~ s/\(DE\-588\)//;
            my $esc_ks = aleph_escape($ks);
            # reformat nonsorting leading article:
            $ks =~ s/<</[/;
            $ks =~ s/>>/]/;
            $line = qq|<p class="catalog"><a id="k$gnd" href="javascript:kss('$esc_ks','$gnd')">$ks</a></p>\n|;
            $ret .= $line;
        }
    }
    $ret;
}

sub aleph_escape {
    # -- normalisiere Interpunktion und Zeichensatz einer String,
    # -- um sie in einem CCL-String für Aleph zu verwenden.
    local $_ = shift or return '';
    # remove nonsorting leading article:
    s|<<.*>> ?||;
    $_ = utf8sort_lc($_);
    # normalize blanks
    s/  +/ /g;
    s/^\s+//;
    s/\s+$//;
    $_;
}    

sub write_page {
    my($descriptor,$did,$context,$liste)=@_;
    my $outfile =  qq|$OutDir$did.html|;
    local $_ = $Template;
    s/%%DESCRIPTOR%%/$descriptor/g;
    s/%%CONTEXT%%/$context/;
    s/%%LISTE%%/$liste/;
    if ( $Verbose ) {
        print $did, ".html\n";
    }
    open(OUT, ">$outfile") or die("cannot write $outfile: $!");
    print OUT $_;
    close OUT;
}
