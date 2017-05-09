#!/usr/bin/perl -w

# File:     swasd-hierarchie.pl
# Autor:    andres.vonarx@unibas.ch
# ----------------------------------------------
# Programmlogik:
# - liest die BIB Datei (Auszug) und erstellt eine
#   Liste der verwendeten Deskriptoren; Sachunterschlagwörter
#   werden proviorisch ebenfalls als Deskriptoren
#   behandelt. (Wenn das Sach-USW nicht als Deskriptor in
#   der AUT-Datei vorkommt, wird es ignoriert).
#
#   Beispiel 1:
#      690FC |a Stadtverkehr |x Stadtverkehrspolitik
#      --> sowohl "Stadtverkehr" wie "Stadtverkehrspolitik" sind Deskriptoren
#
#   Beispiel 2:
#      690FC |a Binnenschiffahrt |x Rheinschiffahrt |2 SWA
#      --> nur "Binnenschiffahrt" ist ein Deskriptor
#
# - liest die AUT Datei (Auszug) und erstellt eine
#   Hierarchie der Deskriptoren mit Querverweisen.
#   Es werden nur die Deskriptoren verwendet,
#   die in der Liste der BIB Dateien vorkommen.
#
# - ordnet die AUT Hierarchie, fügt die BIB-Dossiers
#   zum zugehörigen Deskriptor und gibt alles als
#   XML Datei aus.
#
# History:
# 10.06.2002 Testversion
# 14.06.2002 Sortierlogik swa
# 20.06.2002 erweiterte <info>
# 18.10.2002 Sach-Unterschlagwörter (690FC $x) werden auch in die Hierarchie
#    aufgenommen, sofern es Deskriptoren sind.
# 22.12.2003 Attribut "definition" fuer <dossiers>; Element <info> entfernt
# 26.05.2004 Element <dossier> enthält zusätzlich ein Attribut "suchstring",
#    mit der eine find-acc Abfrage in Aleph gemacht werden kann (7bit ASCII)
# 16.02.2005 $FSEP zbd $SUBSEP lokal definiert
# 04.05.2010 neue Top-Kategorien "<thesaurus>"
# 02.06.2010 verschiedene Vereinfachungen...

use strict;
use ava::sort::utf8;
use Data::Dumper; $Data::Dumper::Indent=1;

# input files;
my $Aut = 'tmp/aut-extract.txt';
my $Bib = 'tmp/bib-extract.txt';

# output file
my $XML  = '-';
my $Err  = 'errors.txt';

# Sortierung
my $SEP = "\x1E";   # interner Separator fuer Sortierung
my $FSEP = quotemeta('#');
my $SUBSEP = quotemeta('$');

my @Thesauri = (
    'Volkswirtschaft',
    'Betriebswirtschaft',
    'Wirtschaftssektoren',
    'Nachbarwissenschaften',
    );

my($THES, $DESK, $LINKS, $DOSS, $TOPID, $SID, $TID, $DID, $SACHUSW);
my %Sortierung = get_sort_codes();
open(ERR,">$Err") or die "cannot write $Err: $!";
read_bib();
read_aut();
check_deskriptoren();
serialize_thesaurus();

END {
    close ERR;
    if ( (stat($Err))[7] ) {
        print "  ** encountered some errors. See $Err\n";
    }
    else {
        unlink $Err;
    }
}


# ---------------
sub read_bib {
# ---------------
    # lese BIB daten in eine lookup table $DOSS mit key DESKRIPTOR
    local(*B, $_);
    open(B, "<$Bib") or die "cannot read $Bib: $!";
    while ( <B> ) {
        chomp;
        my($desk,$sache,$ort,$bibsysno,$def) = split /$FSEP/;

        ### Ergaenzung 26.05.2004: suchstring
        my $suchstring = make_suchstring($desk,$sache,$ort);

        my $doss_info = {
            ort => $ort,
            sache => $sache,
            bibsysno => $bibsysno,
            suchstring => $suchstring,
            def => $def,
            };
        push( @{$DOSS->{$desk}}, $doss_info );

        ### Ergänzung 18.10.2002:
        ### Unterschlagwort wird zusätzlich in die Hierarchie aufgenommen.
        if ( $sache ) {
            $doss_info->{hauptsw} = $desk;
            push( @{$DOSS->{$sache}}, $doss_info );
            $SACHUSW->{$sache}=1;
        }
    }
    close B;
}

# ---------------
sub read_aut {
# ---------------

    # lese AUT daten in diverse lookup tables:
    #
    # - $THES bildet den Thesaurus als hierarchische HASH ref ab (Subthesaurus,
    #   Teilthesaurus, Deskriptor). Unterster Knoten ist die Dokument ID.
    #   * es werden nur die Deskriptoren aufgenommen, die in der BIB-Aufnahme vorkommen
    #
    # - $LINKS enthält den Deskriptornamen (Schlüssel: Deskriptor-ID).
    #   Diese Tabelle wird für Querverweise von gleichlautenden Deskriptoren
    #   verwendet, die an mehr als einer Stelle im Thesaurus auftauchen.
    #
    # - $DESK enthält ARRAY refs auf Synonyme und Verwandte Begriffe.
    #   Schlüssel ist der Deskriptor

    local(*A, $_);
    open(A, "<$Aut") or die "cannot read $Aut: $!";
    while ( <A> ) {
        chomp;
        my($top,$st,$tt,$desk, $bibsysno,$synonym,$oberbegriff,$verwandt)=split /$FSEP/;
        next unless ( $DOSS->{$desk} );
        my $DID = 'did' . ++$DID;
        my @synonym = split(/$SUBSEP/, $synonym);
        my @oberbegriff = split(/$SUBSEP/, $oberbegriff);
        my @verwandt = split(/$SUBSEP/, $verwandt);
        $THES->{$top}->{$st}->{$tt}->{$desk} = $DID;
        my $kontext = ( $tt ) ? "$st. $tt" : $st;
        $LINKS->{$DID} = "$kontext. $desk";
        $DESK->{$desk}->{synonym} = \@synonym,
        $DESK->{$desk}->{oberbegriff} = \@oberbegriff,
        $DESK->{$desk}->{verwandt} = \@verwandt,
        push( @{$DESK->{$desk}->{links}}, $DID);
    }
    close A;
}

# ---------------
sub serialize_thesaurus {
# ---------------
    my $treeitem;   # counter for Tigra Tree Menu Items (bis hinunter zum Deskriptor)
    open(T,">$XML") or die "cannot write $XML: $!";
    print T qq|<?xml version="1.0" encoding="UTF-8" ?>\n|
        .qq|<swa_sachsystematik>\n|;
    foreach my $top ( @Thesauri ) {
        $treeitem++;
        my $pid = 'pid' . ++$TOPID;
        print T qq|<thesaurus name="$top" id="$pid" treeitem="$treeitem">\n|;
        foreach my $st ( sort utf8sort keys %{$THES->{$top}} ) {
            my $sid = 'sid' . ++$SID;
            $treeitem++;
            print T qq|<subthesaurus name="$st" id="$sid" treeitem="$treeitem">\n|;
            foreach my $tt ( sort utf8sort keys %{$THES->{$top}->{$st}} ) {
                my $tid = 'tid' .++$TID;
                $treeitem++;
                print T qq|<teilthesaurus name="$tt" id="$tid" treeitem="$treeitem">\n|;
                foreach my $desk( sort utf8sort keys %{$THES->{$top}->{$st}->{$tt}} ) {
                    my $DID = $THES->{$top}->{$st}->{$tt}->{$desk};
                    serialize_deskriptor($desk, $DID,++$treeitem);
                }
                print T "</teilthesaurus>\n";
            }
            print T "</subthesaurus>\n";
        }
        print T "</thesaurus>\n";
    }
    print T "</swa_sachsystematik>\n";
    close T;
}

# ---------------
sub serialize_deskriptor {
# ---------------
    my $desk = shift;
    my $DID = shift;
    my $treeitem=shift;

    print T qq|<deskriptor name="$desk" id="$DID" treeitem="$treeitem">\n|;
    print T '<siehe_auch>', "\n";
    my @sa;
    foreach my $link ( @{$DESK->{$desk}->{links}} ) {
        unless ( $link eq $DID ) {
            push(@sa, "$LINKS->{$link}$SEP$link");
        }
    }
    @sa = sort utf8sort @sa;
    while( @sa ) {
        local $_ = shift @sa;
        my($text, $link) = split /$SEP/;
        print T '<querverweis linktext="', $text, '" linkid="', $link, '"/>', "\n";
    }
    print T '</siehe_auch>', "\n";

    print T '<synonyme>', "\n";
    foreach my $synonym ( @{$DESK->{$desk}->{synonym}} ) {
        print T '<synonym name="', $synonym, '"/>', "\n";
    }
    print T '</synonyme>', "\n";

    print T '<verwandte_begriffe>', "\n";
    foreach my $verwandt ( @{$DESK->{$desk}->{verwandt}} ) {
        print T '<vb_siehe_auch name="', $verwandt, '"/>', "\n";
    }
    foreach my $oberbegriff ( @{$DESK->{$desk}->{oberbegriff}} ) {
        print T '<vb_oberbegriff name="', $oberbegriff, '"/>', "\n";
    }
    print T '</verwandte_begriffe>', "\n";

    print T '<dossiers>', "\n";
    serialize_dossier($desk, $DID);
    print T '</dossiers>', "\n";

    print T '</deskriptor>', "\n";
}

# ---------------
sub serialize_dossier {
# ---------------
    my $key=shift;
    my $DID=shift;

    my $aref = $DOSS->{$key};
    my @tmp;

    # sortierung
    foreach my $href ( @$aref ) {
        my $deskriptor = $href->{hauptsw} || $key;
        my $sachcode = $href->{sache} ? 1 : 0;
        my $ortcode = 0;
        if ( $href->{ort} ) {
            if ( $Sortierung{$href->{ort}} ) {
                $ortcode = $Sortierung{$href->{ort}};
            } else {
                # warn('!! KEIN SORTIERCODE FUER ' .$href->{ort} ."\n");
                $ortcode = '4';
            }
        }
        my $tmp = $deskriptor .$SEP .$sachcode .$SEP .$href->{sache} .$SEP .$ortcode .$SEP
            .$href->{ort} .$SEP .$href->{bibsysno} .$SEP .$href->{suchstring} .$SEP .$href->{def};
        push(@tmp, $tmp);
    }
    @tmp = sort utf8sort @tmp;
    while( @tmp ) {
        local $_ = shift @tmp;
        my ($deskriptor,$sachcode,$sache,$ortcode,$ort,$bibsysno,$suchstring,$def) = split /$SEP/;
        print T qq|<dossier begriff="$deskriptor" unterbegriff_sache="$sache" |;
        print T qq|unterbegriff_ort="$ort" sortiercode_ort="$ortcode" bibsysno="$bibsysno" suchstring="$suchstring"|;
        if ( $def ) {
            print T qq| definition="$def"|;
        }
        print T "/>\n";
    }
}

# ---------------
sub check_deskriptoren {
# ---------------
    # prüft, ob für jeden Deskriptor die nötige Info in der AUT
    # vorhanden ist.
    foreach my $desk ( keys %$DOSS ) {
        unless ( $DESK->{$desk} ) {
            unless ( $SACHUSW->{$desk} ) {
                print ERR "keine AUT fuer '$desk'\n";
                my $aref = $DOSS->{$desk};
                foreach my $doss ( @$aref ) {
                    print ERR " BIB: $doss->{bibsysno}\n";
                }
            }
        }
    }
    $SACHUSW = '';
}

# ---------------
sub get_sort_codes {
# ---------------
  (
    #
    # ohne USW               => 0,
    #
    # mit USW Ort:
    #
    'Schweiz'                => 1,
    #
    'Deutsche Schweiz'       => 2,
    'Romandie, Tessin'       => 2,
    #
    'Aargau'                 => 3,
    'Appenzell Innerrhoden'  => 3,
    'Appenzell Ausserrhoden' => 3,
    'Basel-Landschaft'       => 3,
    'Basel-Landschaft, Basel-Stadt' => 3,
    'Baselland'              => 3,
    'Basel (Kanton)'         => 3,
    'Basel-Stadt (Kanton)'   => 3,
    'Bern (Kanton)'          => 3,
    'Freiburg (Kanton)'      => 3,
    'Fribourg (Kanton)'      => 3,
    'Genf (Kanton)'          => 3,
    'Genève (Kanton)'        => 3,
    'Glarus (Kanton)'        => 3,
    'Graubünden'             => 3,
    'Jura'                   => 3,
    'Jura (Kanton)'          => 3,
    'Luzern (Kanton)'        => 3,
    'Neuchâtel (Kanton)'     => 3,
    'Neuenburg (Kanton)'     => 3,
    'Nidwalden'              => 3,
    'Obwalden'               => 3,
    'St.Gallen (Kanton)'     => 3,
    'St. Gallen (Kanton)'    => 3,
    'Schaffhausen (Kanton)'  => 3,
    'Solothurn (Kanton)'     => 3,
    'Schwyz (Kanton)'        => 3,
    'Thurgau'                => 3,
    'Tessin'                 => 3,
    'Ticino'                 => 3,
    'Uri'                    => 3,
    'Vaud'                   => 3,
    'Valais'                 => 3,
    'Waadt'                  => 3,
    'Wallis'                 => 3,
    'Zug (Kanton)'           => 3,
    'Zürich (Kanton)'        => 3,
    #
    'Uebrige Kantone'        => 4,
    'Übrige Kantone'         => 4,
    'übrige Kantone'         => 4,
    #
    #
  )
}

# ---------------
sub make_suchstring {
# ---------------
    my ($desk,$sache,$ort) = @_;
    local $_ = $desk .' ' . $sache . ' ' . $ort;
    $_ = utf8sort_lc($_);
    s/\s+$//;
    s/ +/%20/g;
    $_;
}

