#!/bin/bash

# make-luzern.sh
# bereite Daten auf zur hierarchischen Darstellung der Archive der ZHB Luzern
# nur für HAN-Gesamttektonik
# --------------------------------------------------------------------
# Input:
#   dsv05.seq
#
# Output:
#   JS-Code fuer Tigra Tree Menu: 
#       tree_items.js  (Personen)
#       
# --------------------------------------------------------------------
# history:
#   rewrite 25.11.2014/ava
#   adaption für ZHB Luzern basierend auf make-gosteli.sh 13.01.2015/bmt
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
HOME=/opt/scripts/htb/han_luzern_tektonik

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
say 'ZHB Luzern'
say '-------------------------'
say 'Laufzeit ca. 1 Minuten. Bitte Geduld...'
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


say "* extrahiere Luzerner-Daten aus dsv05.seq"
perl $BIN_DIR'filter_alephseq.pl' \
   --input=$DSV05_SEQ \
   --output='tmp/luzern-all.seq' \
   --marc='852 a' \
   --regex='Luzern ZHB' \
   --noignorecase;


say "* konvertiere Aleph Sequential nach MARC21 XML"
$BIN_DIR/htb_alephseq_to_marcxml tmp/luzern-all.seq tmp/luzern-all.xml

say "* extrahiere 490er"
$BIN_DIR/htb_alephseq_extract_490 tmp/luzern-all.seq tmp/luzern-490.seq

say "* extrahiere Toplevel Info (Personen)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/extract-top-info.xsl -s:tmp/luzern-all.xml -o:tmp/p-top.txt typ=p
sed -i 's/&/&amp;/g' tmp/p-top.txt
sed -i 's/<<//g' tmp/p-top.txt
sed -i 's/>>//g' tmp/p-top.txt

say "* extrahiere Toplevel Info (Körperschaften)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/extract-top-info.xsl -s:tmp/luzern-all.xml -o:tmp/k-top.txt typ=k
sed -i 's/&/&amp;/g' tmp/k-top.txt
sed -i 's/<<//g' tmp/k-top.txt
sed -i 's/>>//g' tmp/k-top.txt

say "* füge Toplevel Personen und Verbände zusammen"
cat tmp/p-top.txt tmp/k-top.txt > tmp/top.txt

say "* entferne vertrauliche Archive ZHB Luzern"
sed -i '/Zentralbibliothek Luzern/d' tmp/top.txt 
sed -i '/Zentral- und Hochschulbibliothek Luzern/d' tmp/top.txt
sed -i '/Kantonsbibliothek/d' tmp/top.txt
# Entferne Datensatz 000297409  hide_this ead Aufnahme für Einzeldokumente
sed -i '/^000297409/d' tmp/top.txt

say "* generiere top-down Hierarchie" 
perl $BIN_DIR/htb_build_hierarchy_top_down --toplist=tmp/top.txt --list490=tmp/luzern-490.seq --outfile=tmp/hierarchy.xml

say "* reichere Hierarchie an"
perl $BIN_DIR/enrich-hierarchy-with-marcdata-simple.pl --infile=tmp/hierarchy.xml --marcfile=tmp/luzern-all.xml --outfile=tmp/hierarchy-full.xml 

say "* Entferne spitze Klammern (Artikelkennzeichnung im Titelfeld)"
sed -i "s/&lt;&lt;//g" tmp/hierarchy-full.xml
sed -i "s/&gt;&gt;//g" tmp/hierarchy-full.xml

say "* generiere JS-TigraTree Menu (Personen)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/tigra_tree_menu_full.xsl \
    -s:tmp/hierarchy-full.xml \
    -o:tree_items.js \
    INFOXML=`pwd`/info-luzern.xml \
    VARNAME=TREE_ITEMS_P \
    HTITLE=1

if [ "$DO_CLEANUP_TEMP" = "1" ]; then
    say "* clean up"
    rm -f tmp/*
fi

if [ "$DO_UPLOAD_FILES" = "1" ]; then
    say "* uploading files"
    scp -q tree_items.js webmaster@ub2.unibas.ch:/export/www/htdocs/ibb/api/luzern/./
    echo ""
    echo "Testseiten (UB Website):"
    echo "  http://ub2.unibas.ch.ub.unibas.ch/ibb/api/luzern/archiv-content.html"
    echo ""
fi

say "* aktualisiere HAN-Verbundtektonik"
# Die HAN-Verbundtektonik wird nicht von Grund auf neu generiert, sondern klebt nur die tree-items.js-Dateien der Einzelhierarchien zusammen.
sh ../han_tektonik/make-han.sh

NOW=`date`
say "END: $NOW"
