#!/bin/bash

# make-tektonik.sh
# bereite Daten auf zur hierarchischen Darstellung der UB HAD
# --------------------------------------------------------------------
# Input:
#   dsv05.seq
#
# Output:
#   JS-Code fuer Tigra Tree Menu: 
#       tree_items_p.js  (Personen)
#       tree_items_v.js  (Vereinsarchive)
# --------------------------------------------------------------------
# history:
#   rewrite 25.11.2014/ava
#   rewrite for UB Tektonik 05.02.2015/bmt
#   anpassung an neues HAN-Format 12.01.2016/bmt


# -------------------------------
# Optionen
# -------------------------------
QUIET=0             # wenn 1: bleibe stumm
DO_REFRESH_DSV05=1  # wenn 1: aktualisiere dsv05.seq
DO_CLEANUP_TEMP=1   # wenn 1: putze temporaere Dateien
DO_UPLOAD_FILES=1   # wenn 1: lade Dateien auf Webserver


# -------------------------------
# files & directories
# -------------------------------

DSV05_DIR=/opt/data/dsv05
DSV05_SEQ=$DSV05_DIR/dsv05.seq
BIN_DIR=/opt/bin/htb/
HOME=/opt/scripts/htb/ub_tektonik

# -------------------------------
# Funktionen
# -------------------------------

backup_file () {
    # backup a file, provided it exists and no backup exists yet
    if [ ! -z "$1" -a -f "$1" ]; then
        backup_extension=`perl -MPOSIX -e 'print strftime(".%Y%m%d",localtime)'`$USER
        backup_filename="archiv/$1$backup_extension"
        if [ ! -f $backup_filename ]; then
            cp "$1" "$backup_filename"
        fi
    fi
}

say () {
    # Ausgabe auf Bildschirm (laesst sich unterdruecken mit QUIET=1)
    if [ "$QUIET" != "1" ]; then echo "$1"; fi
}

# -------------------------------
# Hauptprogramm
# -------------------------------

say '-------------------------'
say 'UB Basel: Tektonik HAD'
say '-------------------------'
say 'Laufzeit ca. 4 Stunden. Bitte Geduld...'
say ''
NOW=`date`
say "START: $NOW"

if [ "$DO_REFRESH_DSV05" = "1" ]; then
   say "* aktualisere DSV05"
   cd $DSV05_DIR
   ./download-dsv05-sequential.sh
fi

cd $HOME

say "* Backup alte Dateien"
backup_file tree_items.js
rm -f tree_items.js

say "* extrahiere UB HAD-Daten aus dsv05.seq"
#Suche nach 'UB Basel' findet auch Katalogisate der UB Basel Wirtschaft. Deshalb "$" im Regex.
perl $BIN_DIR'filter_alephseq.pl' \
  --input=$DSV05_SEQ \
   --output='tmp/tektonik-all.seq' \
   --marc='852 a' \
   --regex='Basel UB$' \
   --noignorecase;
   
say "* Suche versteckte Katalogisate"
#Katalogsate mit hide_this sollen in der Hierarchie nicht angezeigt werden.
perl $BIN_DIR'filter_alephseq.pl' \
  --input='tmp/tektonik-all.seq' \
   --output='tmp/tektonik-hide.seq' \
   --marc='909 f' \
   --regex='hide_this' \
   --noignorecase;
   
   
say "* konvertiere Aleph Sequential nach MARC21 XML"
$BIN_DIR/htb_alephseq_to_marcxml tmp/tektonik-all.seq tmp/tektonik-all.xml

say "* extrahiere 490er"
$BIN_DIR/htb_alephseq_extract_490 tmp/tektonik-all.seq tmp/tektonik-all-490.seq
$BIN_DIR/htb_alephseq_extract_490 tmp/tektonik-hide.seq tmp/tektonik-hide-490.seq

say "* extrahiere 773er"
$BIN_DIR/htb_alephseq_extract_773 tmp/tektonik-all.seq tmp/tektonik-all-773.seq
$BIN_DIR/htb_alephseq_extract_773 tmp/tektonik-hide.seq tmp/tektonik-hide-773.seq

say "* Entferne versteckte Katalogisate"
cat tmp/tektonik-all-490.seq tmp/tektonik-hide-490.seq | sort -r | uniq -u > tmp/tektonik-490.seq
cat tmp/tektonik-all-773.seq tmp/tektonik-hide-773.seq | sort -r | uniq -u > tmp/tektonik-773.seq

say "* Füge 490er und 773er zusammen"
cat tmp/tektonik-490.seq tmp/tektonik-773.seq | sort > tmp/tektonik-490-773.seq

#Keine Toplevel-Extraktion: Daten liegen Hardcodiert in top.txt Grund: Kein Aktenbildner in Katalogisaten, kein Zuwachs, geringe Anzahl Top-Level-Kandidaten
#top.txt muss im HOME-VERZEICHNIS liegen.

say "* generiere top-down Hierarchie"
perl $BIN_DIR/htb_build_hierarchy_top_down --toplist=top.txt --list490=tmp/tektonik-490-773.seq --outfile=tmp/hierarchy.xml

say "* reichere Hierarchie an"
perl $BIN_DIR/enrich-hierarchy-with-marcdata-simple.pl --infile=tmp/hierarchy.xml --marcfile=tmp/tektonik-all.xml --outfile=tmp/hierarchy-full.xml --author=Y

say "* Entferne spitze Klammern (Artikelkennzeichnung im Titelfeld)"
sed -i "s/&lt;&lt;//g" tmp/hierarchy-full.xml
sed -i "s/&gt;&gt;//g" tmp/hierarchy-full.xml

say "* generiere JS-TigraTree Menu"
saxon9 -versionmsg:off -xsl:$BIN_DIR/tigra_tree_menu_full.xsl \
	-s:tmp/hierarchy-full.xml \
    -o:tree_items.js \
    INFOXML=`pwd`/info-tektonik.xml \
    VARNAME=TREE_ITEMS \
    HTITLE=1


if [ "$DO_CLEANUP_TEMP" = "1" ]; then
    say "* clean up"
    rm -f tmp/*
fi

if [ "$DO_UPLOAD_FILES" = "1" ]; then
    say "* uploading files"
    scp -q tree_items.js webmaster@www:/export/www/htdocs/ibb/api/tektonik/./
    echo ""
    echo "Testseiten (UB Website):"
    echo "  http://www.ub.unibas.ch/ibb/api/tektonik/archiv-content.html"
    echo ""
fi

say "* aktualisiere HAN-Verbundtektonik"
# Die HAN-Verbundtektonik wird nicht von Grund auf neu generiert, sondern klebt nur die tree-items.js-Dateien der Einzelhierarchien zusammen.
sh ../han_tektonik/make-han.sh

NOW=`date`
say "END: $NOW"
