#!/bin/bash

# make-trogen.sh
# bereite Daten auf zur hierarchischen Darstellung der Archive der Kantonsbibliothek Appenzell Ausserrhoden
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
#   adaption für KB Appenzell Ausserrhoden basierenf auf make-gosteli.sh 13.01.2015/bmt
#   adaption für neues HAN-Format 12.01.2016/bmt

# -------------------------------
# Optionen
# -------------------------------
QUIET=0             # wenn 1: bleibe stumm
DO_REFRESH_DSV05=1  # wenn 1: aktualisiere dsv05.seq
DO_CLEANUP_TEMP=0   # wenn 1: putze temporaere Dateien
DO_UPLOAD_FILES=1   # wenn 1: lade Dateien auf Webserver


# -------------------------------
# files & directories
# -------------------------------

DSV05_DIR=/opt/data/dsv05/
DSV05_SEQ=$DSV05_DIR/dsv05.seq
BIN_DIR=/opt/bin/htb/
HOME=/opt/scripts/htb/han_kb_trogen

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
say 'KB Trogen: Archive'
say '-------------------------'
say 'Laufzeit ca. 5 Minuten. Bitte Geduld...'
say ''
NOW=`date`
say "START: $NOW"

if [ "$DO_REFRESH_DSV05" = "1" ]; then
    say "* aktualisiere DSV05"
    cd $DSV05_DIR
    ./download-dsv05-sequential.sh
fi

cd $HOME

say "* Backup alte Dateien"
backup_file tree_items.js
rm -f tree_items.js


say "* extrahiere Trogen-Daten aus dsv05.seq"
perl $BIN_DIR'filter_alephseq.pl' \
   --input=$DSV05_SEQ \
   --output='tmp/trogen-all.seq' \
   --marc='852 a' \
   --regex='Ausserrhoden' \
   --noignorecase;

say "* extrahiere alle Aufnahmen der Verzeichnisstufe Bestand=Fonds"
perl $BIN_DIR'filter_alephseq.pl' \
   --input='tmp/trogen-all.seq'\
   --output='tmp/trogen-fonds.seq' \
   --marc='351 c' \
   --regex='Fonds' \
   --noignorecase;

say "* konvertiere Aleph Sequential nach MARC21 XML"
$BIN_DIR/htb_alephseq_to_marcxml tmp/trogen-all.seq tmp/trogen-all.xml
$BIN_DIR/htb_alephseq_to_marcxml tmp/trogen-fonds.seq tmp/trogen-fonds.xml

say "* extrahiere 490er"
$BIN_DIR/htb_alephseq_extract_490 tmp/trogen-all.seq tmp/trogen-490.seq

say "* extrahiere Toplevel Info (Personen)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/extract-top-info.xsl -s:tmp/trogen-fonds.xml -o:tmp/p-top.txt typ=p
sed -i 's/&/&amp;/g' tmp/p-top.txt

say "* extrahiere Toplevel Info (Verbände)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/extract-top-info.xsl -s:tmp/trogen-fonds.xml -o:tmp/v-top.txt typ=k
sed -i 's/&/&amp;/g' tmp/v-top.txt

say "* füge Toplevel Personen und Verbände zusammen"
cat tmp/p-top.txt tmp/v-top.txt > tmp/top.txt
sed -i "s/<title>Psychosophische Gesellschaft<\/title>/<title>Collectio Magica et Occulta : Archiv der Psychosophischen Gesellschaft in der Schweiz \(19.-21. Jh.\)<\/title>/g" tmp/top.txt
sed -i "s/Psychosophische Gesellschaft/AAAPsychosophische Gesellschaft/" tmp/top.txt
sed -i "/Kantonsbibliothek Appenzell Ausserrhoden/d" tmp/top.txt

say "* generiere top-down Hierarchie" 
perl $BIN_DIR/htb_build_hierarchy_top_down --toplist=tmp/top.txt --list490=tmp/trogen-490.seq --outfile=tmp/hierarchy.xml

say "* reichere Hierarchie an"
perl $BIN_DIR/enrich-hierarchy-with-marcdata-simple.pl --infile=tmp/hierarchy.xml --marcfile=tmp/trogen-all.xml --outfile=tmp/hierarchy-full.xml --author=N

say "* Entferne spitze Klammern (Artikelkennzeichnung im Titelfeld)"
sed -i "s/&lt;&lt;//g" tmp/hierarchy-full.xml
sed -i "s/&gt;&gt;//g" tmp/hierarchy-full.xml

say "* generiere JS-TigraTree Menu (Personen)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/tigra_tree_menu_full.xsl \
    -s:tmp/hierarchy-full.xml \
    -o:tree_items.js \
    INFOXML=`pwd`/info-trogen.xml \
    VARNAME=TREE_ITEMS_P \
    HTITLE=1

sed -i "s/AAAPsychosophische Gesellschaft/Psychosophische Gesellschaft/" tmp/top.txt

if [ "$DO_CLEANUP_TEMP" = "1" ]; then
    say "* clean up"
    rm -f tmp/*
fi

if [ "$DO_UPLOAD_FILES" = "1" ]; then
    say "* uploading files"
    scp -q tree_items.js webmaster@www:/export/www/htdocs/ibb/api/trogen/./
    echo ""
    echo "Testseiten (UB Website):"
    echo "  http://www.ub.unibas.ch/ibb/api/trogen/index.html"
    echo ""
fi

say "* aktualisiere HAN-Verbundtektonik"
# Die HAN-Verbundtektonik wird nicht von Grund auf neu generiert, sondern klebt nur die tree-items.js-Dateien der Einzelhierarchien zusammen.
sh ../han_tektonik/make-han.sh

NOW=`date`
say "END: $NOW"
