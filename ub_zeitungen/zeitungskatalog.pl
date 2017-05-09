#!/usr/bin/perl

=for doku

    zeitungskatalog.pl

    input: Textdatei, tab-separated, mit den Feldern
            - Systemnummer
            - Titel
            - Code (909A_ $x )
            - externer_Link

    output: HTML-Seiten

    Stand: 11.05.2011/andres.vonarx@unibas.ch

=cut

use strict;
use ava::sort::utf8;
use FindBin;
use lib "$FindBin::Bin/../tools";
use CMS_AZ_Balken;

my $Laendercodes= "$FindBin::Bin/ids_laendercodes.txt";             # Konkordanz Laendercode - Bezeichnung
my $Templatefile= "$FindBin::Bin/zeitungskatalog-template.html";    # HTML-Template
my $Infile      = "$FindBin::Bin/tmp/ztgbs.txt";                    # Extrakt aus Katalogdaten
my $OUTDIR      = "$FindBin::Bin/tmp";

my $Template = parse_template();

my $Alphabetisch = {
    zeitungen_a_bis_z => {
        what => 'Laufende Zeitungen: A-Z',
        filter => sub { /\bhist\b/ ? 0 : 1 },
    },
    zeitungen_historisch_basel => {
        what => 'Historische Zeitungen: Region Basel',
        filter => sub { /^szbs hist\b/ ? 1 : 0 },
    },
    zeitungen_historisch_schweiz => {
        what => 'Historische Zeitungen: Übrige Schweiz',
        filter => sub { /^sz hist\b/ ? 1 : 0 },
    },
    zeitungen_historisch_ausland => {
        what => 'Historische Zeitungen: International',
        filter => sub { (/\bhist\b/ && (! /^sz /) && (! /^szbs /)) ? 1 : 0 },
    }
};

foreach my $key ( sort keys %$Alphabetisch ) {
    my $item = $Alphabetisch->{$key};
    print "  ", $item->{what}, "\n";
    my $outfile = $OUTDIR .'/' .$key .".html";
    my @liste;
    my $AZ=CMS_AZ_Balken->new;
    open(IN,"<$Infile") or die("cannot read $Infile: $!");
    <IN>;   # zap header
    while ( <IN> ) {
        chomp;
        my($sysno, $titel, $code, $link )=split(/\t/);
        $_ = $code;
        next unless ( $item->{filter}() );
        my($anzeige,$sort)=normalisiere_titel($titel);
        $AZ->register($sort);
        my $letter=$AZ->normalize_first_letter($sort);
        my $line = qq|$letter\t$sort\t$anzeige\t$sysno\t$link|;
        push(@liste, $line);
    }
    close IN;
    @liste = sort @liste;
    my $page='';
    while ( @liste ) {
        $_ = shift @liste;
        my($letter,$sort,$anzeige,$sysno,$link)=split /\t/;
        $page .= $AZ->navi_balken_wenn_noetig($sort);
        $page .= formatiere_titel($anzeige,$sysno,$link);
    }
    $page = formatiere_seite(\$page, $item->{what});
    open(OUT, ">$outfile") or die("cannot write $outfile: $!");
    print OUT $page;
    close OUT;
}

my $what = 'Laufende Zeitungen: nach Ländern';
print "  $what\n";
my $Codes  = parse_laendercodes();
my @liste;
open(IN,"<$Infile") or die("cannot read $Infile: $!");
<IN>;
while ( <IN> ) {
    chomp;
    my($sysno, $titel, $code, $link )=split(/\t/);
    next if ( $code =~ /\bhist\b/ );
    my($anzeige,$sort)=normalisiere_titel($titel);
    my $land = $Codes->{$code};
    unless ( $land ) {
        warn("\t!! Ländercode $code ist unbekannt (SysNo: $sysno)\n");
        next;
    }
    my $line = qq|$land\t$sort\t$anzeige\t$sysno\t$link|;
    push(@liste, $line);
}
close IN;
@liste = sort @liste;
my $prev_land;
my $page='';
while ( @liste ) {
    $_ = shift @liste;
    my($land,$sort,$anzeige,$sysno,$link)=split /\t/;
    if ( $land ne $prev_land ) {
        $prev_land = $land;
        $page .= formatiere_land($land);
    }
    $page .= formatiere_titel($anzeige,$sysno,$link);
}
$page = formatiere_seite(\$page,$what);
my $outfile = $OUTDIR .'/zeitungen_nach_laendern.html';
open(OUT, ">$outfile") or die("cannot write $outfile: $!");
print OUT $page;
close OUT;

# ---------------------------------------------------------------------------

sub parse_laendercodes {
    my $ret;
    open(F, "<$Laendercodes") or die("cannot read $Laendercodes: $!");
    while ( <F> ) {
        next if ( /^#/ );
        next if ( /^\s*$/ );
        chomp;
        my($code,$text)=split /\s*;\s*/;
        $ret->{$code} = $text;
    }
    close F;
    $ret->{sz} = 'Schweiz (übrige Schweiz)';
    $ret->{szbs} = 'Schweiz (Region Basel)';
    $ret;
}

sub normalisiere_titel {
    # in: Titel wie in Aleph
    # out:  ( Anzeigeform, Sortierform )
    my $anzeige = shift;
    my $sort = $anzeige;
    $sort =~ s/^.*>>\s*//;
    $sort = utf8sort_lc($sort);
    $anzeige =~ s/<</[/;
    $anzeige =~ s/>>/]/;
    $anzeige = safe_chars($anzeige);
    ( $anzeige, $sort );
}

sub formatiere_titel {
    my($anzeige,$sysno,$link)=@_;
    $link = safe_chars($link);
    local $_ = ( $link ) ? $Template->{DOUBLE} : $Template->{SIMPLE};
    s/%%SYSNO%%/$sysno/g;
    s/%%TITLE%%/$anzeige/g;
    s/%%EXTERN%%/$link/g;
    $_;
}

sub formatiere_land {
    my $land = shift;
    local $_ = $Template->{LAND};
    s/%%LAND%%/$land/;
    $_;
}

sub formatiere_seite {
    my $ref=shift;
    my $what=shift;
    my $liste = $Template->{LISTE};
    $liste =~ s/%%LISTE%%/$$ref/;
    my $page = $Template->{TEMPLATE};
    $page =~ s|<!-- START CONTENT -->.*<!-- END CONTENT -->|$liste|s;
    $page =~ s|%%TITLE%%|$what|;
    $page;
}

sub safe_chars {
    local $_ = shift or return undef;
    s/\&/&amp;/g;
    s/>/&gt;/g;
    s/</&lt;/g;
    s/\'/&apos;/g;
    s/\"/&quot;/g;
    $_;
}

sub parse_template {
    # HTML-Template in einen HREF einlesen:
    # - die ganze Datei ist zu finden unter ($template->{TEMPLATE}
    # - einzelne Teile, die mit <!-- start TAG --> und <!-- end TAG --> definiert
    #   wurden, sind zu finden unter $template->{TAG}
    my $templatefile = shift;
    local($_, *F);
    my $template;
    open(F,"<$Templatefile") or die("cannot read $Templatefile: $!");
    { local $/; $_= <F>; }
    close F;
    $template->{TEMPLATE}=$_;
    my @tags = /<!-- START (.*?) -->/ig;
    foreach my $tag ( @tags ) {
        ( $template->{$tag} ) = /<!-- START $tag -->(.*)<!-- END $tag -->/sig;
    }
    $template;
}
