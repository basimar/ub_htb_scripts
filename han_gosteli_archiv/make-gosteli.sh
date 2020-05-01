#!/bin/bash

# make-gosteli.sh
# bereite Daten auf zur hierarchischen Darstellung des Gosteli-Archivs
# --------------------------------------------------------------------
# Input:
#   dsv05.seq
#
# Output:
#   JS-Code fuer Tigra Tree Menu: 
#       tree_items_p.js  (Personen)
#       tree_items_v.js  (Vereinsarchive)
#		tree_items_b_js  (Biographische Notizen)
# --------------------------------------------------------------------
# history:
#   rewrite 25.11.2014/ava
#   biographische Notizen added 05.02.2015/bmt
#   Anpassungen für Formatwechsel 04.01.2016/basil.marti@unibas.ch

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

DSV05_DIR=/opt/data/dsv05
DSV05_SEQ=$DSV05_DIR/dsv05.seq
BIN_DIR=/opt/bin/htb/
HOME=/opt/scripts/htb/han_gosteli_archiv

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
say 'UB Bern: Gosteli Archiv'
say '-------------------------'
say 'Laufzeit ca. 15 Minuten. Bitte Geduld...'
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
backup_file tree_items_p.js
backup_file tree_items_v.js
backup_file tree_items_b.js
rm -f tree_items_p.js
rm -f tree_items_v.js
rm -f tree_items_b.js

say "* extrahiere Gosteli-Daten aus dsv05.seq"
perl $BIN_DIR'filter_alephseq.pl' \
    --input=$DSV05_SEQ \
    --output='tmp/gosteli-all.seq' \
    --marc='852 a' \
    --regex='Gosteli' \
    --noignorecase; 

say "* konvertiere Aleph Sequential nach MARC21 XML"
$BIN_DIR/htb_alephseq_to_marcxml tmp/gosteli-all.seq tmp/gosteli-all.xml

say "* extrahiere 490er"
$BIN_DIR/htb_alephseq_extract_490 tmp/gosteli-all.seq tmp/gosteli-490.seq

say "* extrahiere Toplevel Info (Personen)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/extract-top-info.xsl -s:tmp/gosteli-all.xml -o:tmp/p-top.txt typ=p
sed -i 's/&/&amp;/g' tmp/p-top.txt
sed -i 's/<<//g' tmp/p-top.txt
sed -i 's/>>//g' tmp/p-top.txt
# Entferne Datensatz 000221539 Debrit-Vogel, Agnes <- Aktenbildnerin der Biographischen Notizen
sed -i '/^000221539/d' tmp/p-top.txt

say "* extrahiere Toplevel Info (Verbände)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/extract-top-info.xsl -s:tmp/gosteli-all.xml -o:tmp/v-top.txt typ=k
sed -i 's/&/&amp;/g' tmp/v-top.txt
sed -i 's/<<//g' tmp/v-top.txt
sed -i 's/>>//g' tmp/v-top.txt

# Entferne Datensatz 000221539	Gosteli-Stiftung <- Aktenbildnerin der Biographischen Notizen
sed -i '/^000221539/d' tmp/v-top.txt

# Entferne Datensatz 000297327	hide_this ead Aufnahme für Einzeldokumente
sed -i '/^000297327/d' tmp/v-top.txt

say "* extrahiere Toplevel Info (Biografische Notizen)"
# werden nicht generiert, sondern hardcodiert, da nur 1 Toplevel

say "* generiere top-down Hierarchie (Personen)"
perl $BIN_DIR/htb_build_hierarchy_top_down --toplist=tmp/p-top.txt --list490=tmp/gosteli-490.seq --outfile=tmp/p-hierarchy.xml

say "* generiere top-down Hierarchie (Verbände)"
perl $BIN_DIR/htb_build_hierarchy_top_down --toplist=tmp/v-top.txt --list490=tmp/gosteli-490.seq --outfile=tmp/v-hierarchy.xml

say "* generiere top-down Hierarchie (Biographische Notizen)"
perl $BIN_DIR/htb_build_hierarchy_top_down --toplist=b-top.txt --list490=tmp/gosteli-490.seq --outfile=tmp/b-hierarchy.xml

say "* reichere Hierarchie an (Personen)"
perl $BIN_DIR/enrich-hierarchy-with-marcdata-simple.pl --infile=tmp/p-hierarchy.xml --marcfile=tmp/gosteli-all.xml --outfile=tmp/p-hierarchy-full.xml --author=N

say "* reichere Hierarchie an (Verbände)"
perl $BIN_DIR/enrich-hierarchy-with-marcdata-simple.pl --infile=tmp/v-hierarchy.xml --marcfile=tmp/gosteli-all.xml --outfile=tmp/v-hierarchy-full.xml --author=N

say "* reichere Hierarchie an (Biografische Notizen)"
perl $BIN_DIR/enrich-hierarchy-with-marcdata-simple.pl --infile=tmp/b-hierarchy.xml --marcfile=tmp/gosteli-all.xml --outfile=tmp/b-hierarchy-full.xml --author=N

say "* Entferne spitze Klammern (Artikelkennzeichnung im Titelfeld)"
sed -i "s/&lt;&lt;//g" tmp/p-hierarchy-full.xml
sed -i "s/&gt;&gt;//g" tmp/p-hierarchy-full.xml
sed -i "s/&lt;&lt;//g" tmp/v-hierarchy-full.xml
sed -i "s/&gt;&gt;//g" tmp/v-hierarchy-full.xml
sed -i "s/&lt;&lt;//g" tmp/b-hierarchy-full.xml
sed -i "s/&gt;&gt;//g" tmp/b-hierarchy-full.xml

say "* generiere JS-TigraTree Menu (Personen)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/tigra_tree_menu_full.xsl \
    -s:tmp/p-hierarchy-full.xml \
    -o:tree_items_p.js \
    INFOXML=`pwd`/info-gosteli-p.xml \
    VARNAME=TREE_ITEMS_P \
    HTITLE=1

say "* generiere JS-TigraTree Menu (Verbände)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/tigra_tree_menu_full.xsl \
    -s:tmp/v-hierarchy-full.xml \
    -o:tree_items_v.js \
    INFOXML=`pwd`/info-gosteli-v.xml \
    VARNAME=TREE_ITEMS_V \
    HTITLE=1

say "* generiere JS-TigraTree Menu (Biografische Notizen)"
saxon9 -versionmsg:off -xsl:$BIN_DIR/tigra_tree_menu_full.xsl \
    -s:tmp/b-hierarchy-full.xml \
    -o:tree_items_b.js \
    INFOXML=`pwd`/info-gosteli-b.xml \
    VARNAME=TREE_ITEMS_B \
    ROOTNODE=0 \
    HTITLE=1
    
say "* entferne Doppelpunkte auf Dossierebene für die Biografischen Notizen"
# biografische Notizen haben kein Feld 490$$v, weshalb die Einträge mit einem Doppelpunkt beginnen. Wird hier weggeschnitten.
sed -i "s/\[' : /\['/g" tree_items_b.js

say "* fuege Einzelhierarchien zusammen"
cp tree_items_*.js tmp/
#letzte Zeile mit Closing-Tag entfernen
sed -i '/\];/d' tmp/tree_items_*.js
#erste Zeile mit Opening-Tag entfernen
sed -i '1,/var TREE_ITEMS/d' tmp/tree_items_*.js
#Komma nach Closing Tags einfügen
sed -i 's/]$/],/g' tmp/tree_items_*.js

cat tmp/tree_items_p.js tmp/tree_items_v.js tmp/tree_items_b.js > tmp/tree_items.js

sed -i "1s/^/var TREE_ITEMS = [['Gosteli-Archiv','',\n/" tmp/tree_items.js
sed -i '$s/$/\n],\n];/' tmp/tree_items.js

cp tmp/tree_items.js .

if [ "$DO_CLEANUP_TEMP" = "1" ]; then
    say "* clean up"
    rm -f tmp/*
fi

if [ "$DO_UPLOAD_FILES" = "1" ]; then
    say "* uploading files"
    scp -q tree_items_p.js webmaster@ub2.unibas.ch:/export/www/htdocs/ibb/api/gosteli/./
    scp -q tree_items_v.js webmaster@ub2.unibas.ch:/export/www/htdocs/ibb/api/gosteli/./
    scp -q tree_items_b.js webmaster@ub2.unibas.ch:/export/www/htdocs/ibb/api/gosteli/./
    scp -q tree_items.js webmaster@ub2.unibas.ch:/export/www/htdocs/ibb/api/gosteli/./
    echo ""
    echo "Testseiten (UB Website):"
    echo "  http://www.ub2.unibas.ch/ibb/api/gosteli/archivp-content.html"
    echo "  http://www.ub2.unibas.ch/ibb/api/gosteli/archivv-content.html"
    echo "  http://www.ub2.unibas.ch/ibb/api/gosteli/archivb-content.html"
    echo "  http://www.ub2.unibas.ch/ibb/api/gosteli/archiv-content.html"
    echo ""
fi

say "* aktualisiere HAN-Verbundtektonik"
# Die HAN-Verbundtektonik wird nicht von Grund auf neu generiert, sondern klebt nur die tree-items.js-Dateien der Einzelhierarchien zusammen.
sh ../han_tektonik/make-han.sh

NOW=`date`
say "END: $NOW"
