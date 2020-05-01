#!/bin/bash

# make-rorschach.sh
# bereite Daten auf zur hierarchischen Darstellung der Archive des Rorschach Archivs 
# --------------------------------------------------------------------
# Input:
#   dsv05.seq
#
# Output:
#   JS-Code fuer Tigra Tree Menu: 
#       tree_items.js  (Personen)
# --------------------------------------------------------------------
# history:
#   adaption für KB Appenzell Ausserrhoden basierend auf make-trogen.sh 28.06.2017/bmt

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

DSV05_DIR=/opt/data/dsv05/
DSV05_SEQ=$DSV05_DIR/dsv05.seq
BIN_DIR=/opt/bin/htb/
HOME=/opt/scripts/htb/han_rorschach_archiv

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
say 'Rorschach Archiv'
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


say "* extrahiere Rorschach-Daten aus dsv05.seq"
perl $BIN_DIR'filter_alephseq.pl' \
   --input=$DSV05_SEQ \
   --output='tmp/rorschach-all.seq' \
   --marc='852 a' \
   --regex='Rorschach' \
   --noignorecase;

say "* extrahiere alle Aufnahmen der Verzeichnisstufe Bestand=Fonds"
perl $BIN_DIR'filter_alephseq.pl' \
   --input='tmp/rorschach-all.seq'\
   --output='tmp/rorschach-fonds.seq' \
   --marc='351 c' \
   --regex='Fonds' \
   --noignorecase;

say "* konvertiere Aleph Sequential nach MARC21 XML"
$BIN_DIR/htb_alephseq_to_marcxml tmp/rorschach-all.seq tmp/rorschach-all.xml
$BIN_DIR/htb_alephseq_to_marcxml tmp/rorschach-fonds.seq tmp/rorschach-fonds.xml

say "* extrahiere 490er"
$BIN_DIR/htb_alephseq_extract_490 tmp/rorschach-all.seq tmp/rorschach-490.seq

say "* extrahiere Toplevel Info"
saxon9 -versionmsg:off -xsl:$BIN_DIR/extract-top-info.xsl -s:tmp/rorschach-fonds.xml -o:tmp/top.txt typ=p
sed -i 's/&/&amp;/g' tmp/top.txt

say "* generiere top-down Hierarchie" 
perl $BIN_DIR/htb_build_hierarchy_top_down --toplist=tmp/top.txt --list490=tmp/rorschach-490.seq --outfile=tmp/hierarchy.xml

say "* reichere Hierarchie an"
perl $BIN_DIR/enrich-hierarchy-with-marcdata-simple.pl --infile=tmp/hierarchy.xml --marcfile=tmp/rorschach-all.xml --outfile=tmp/hierarchy-full.xml 

say "* Entferne spitze Klammern (Artikelkennzeichnung im Titelfeld)"
sed -i "s/&lt;&lt;//g" tmp/hierarchy-full.xml
sed -i "s/&gt;&gt;//g" tmp/hierarchy-full.xml

say "* generiere JS-TigraTree Menu "
saxon9 -versionmsg:off -xsl:$BIN_DIR/tigra_tree_menu_full.xsl \
    -s:tmp/hierarchy-full.xml \
    -o:tree_items.js \
    INFOXML=`pwd`/rorschach-info.xml \
    VARNAME=TREE_ITEMS \
    HTITLE=1

if [ "$DO_CLEANUP_TEMP" = "1" ]; then
    say "* clean up"
    rm -f tmp/*
fi

if [ "$DO_UPLOAD_FILES" = "1" ]; then
    say "* uploading files"
    scp tree_items.js webmaster@ub2.unibas.ch:/export/www/htdocs/ibb/api/rorschach/tree_items.js
    scp tree_items.js webmaster@ub-webqm:/export/www/htdocs/ibb/api/rorschach/tree_items.js
    echo ""
    echo "Testseiten (UB Website):"
    echo '  http://ub2.unibas.ch/ibb/api/rorschach/index-content.html' 
    echo ""
fi

say "* aktualisiere HAN-Verbundtektonik"
# Die HAN-Verbundtektonik wird nicht von Grund auf neu generiert, sondern klebt nur die tree-items.js-Dateien der Einzelhierarchien zusammen.
sh ../han_tektonik/make-han.sh

NOW=`date`
say "END: $NOW"
