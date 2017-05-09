#!/bin/bash

# make-han.sh
# bereite Daten auf zur hierarchischen Darstellung des HAN-Gesamtbestandes
# --------------------------------------------------------------------
# Input:
#   dsv05.seq
#
# Output:
#   JS-Code fuer Tigra Tree Menu: 
#       tree_item.js
# --------------------------------------------------------------------
# history:
#   rewrite 25.11.2014/ava
#   adaption für HAN-Tektonik 13.01.2015/bmt 

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
HOME=/opt/scripts/htb/han_tektonik/

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
say 'HAN Tektonik'
say '-------------------------'
say 'Laufzeit ca. 1 Minuten. Bitte Geduld...'
say ''
NOW=`date`
say "START: $NOW"

cd $HOME

say "* Backup alte Dateien"
backup_file tree_items.js
rm -f tree_items.js

say "* Lade SWA-Hierarchie"
scp -q webmaster@www:/export/www/htdocs/ibb/api/swapa/tree_items.js tmp/tktswapa

say "* Lade UB-Hierarchie"
scp -q webmaster@www:/export/www/htdocs/ibb/api/tektonik/tree_items.js tmp/tktub

#say "* Lade Bernoulli-Hierarchie"
#scp -q webmaster@www:/export/www/htdocs/ibb/api/bernoulli/tree_items.js tmp/tktbernoulli

say "* Lade ZHB Luzern-Hierarchie"
scp -q webmaster@www:/export/www/htdocs/ibb/api/luzern/tree_items.js tmp/tktluzern

say "* Lade Gosteli-Hierarchien"
scp -q webmaster@www:/export/www/htdocs/ibb/api/gosteli/tree_items_b.js tmp/tktgostelib
scp -q webmaster@www:/export/www/htdocs/ibb/api/gosteli/tree_items_p.js tmp/tktgostelip
scp -q webmaster@www:/export/www/htdocs/ibb/api/gosteli/tree_items_v.js tmp/tktgosteliv

say "* Lade Rorschach-Hierarchie"
scp -q webmaster@www:/export/www/htdocs/ibb/api/rorschach/tree_items.js tmp/tktrorschach

say "* Lade Trogen-Hierarchie"
scp -q webmaster@www:/export/www/htdocs/ibb/api/trogen/tree_items.js tmp/tkttrogen

say "* Bearbeite Hierarchien"
#letzte Zeile mit Closing-Tag entfernen
sed -i '/\];/d' tmp/tkt*
#erste Zeile mit Opening-Tag entfernen
sed -i '1,/var TREE_ITEMS/d' tmp/tkt*
#Komma nach Closing Tags einfügen
sed -i 's/]$/],/g' tmp/tkt*

#Anpassung SWA-Hierarchie 
sed -i 's/javascript:swapa/javascript:bib/g' tmp/tktswapa
sed -i "1s/^/['Schweizerisches Wirtschaftsarchiv','',0,\n/" tmp/tktswapa
sed -i '$s/$/\n],/' tmp/tktswapa
sed -i 's/0,//g' tmp/tktswapa
sed -i "s/{'i0':'icons\/foldergray.gif','i4':'icons\/foldergray.gif','i64':'icons\/foldergray.gif', 'i68':'icons\/foldergray.gif','s0':'na','s4':'na','s64':'na','s68':'na'}//g" tmp/tktswapa

#Anpassung Gosteli-Hierarchie für drei Hierarchien (inkl. Biografische Notizen)
sed -i "1s/^/['Gosteli-Stiftung \/ Fondation Gosteli \/ Gosteli Foundation','',\n/" tmp/tktgostelip
sed -i '$s/$/\n],/' tmp/tktgostelib

#Anpassung Gosteli-Hierarchie für zwei Hierarchien (ohne Biografische Notizen)
#sed -i "1s/^/['Gosteli Archiv','',\n/" tmp/tktgostelip
#sed -i '$s/$/\n],/' tmp/tktgosteliv


say "* Füge Hierarchien zusammen"
cat tmp/tktub tmp/tktswapa tmp/tktgostelip tmp/tktgosteliv tmp/tktgostelib  tmp/tktrorschach tmp/tktluzern tmp/tkttrogen >> tree_items.js #Für Gosteli mit biografische Notizen

say "* Bearbeite Gesamthierarchie"
sed -i "1s/^/var TREE_ITEMS = [['Verbund Handschriften - Archive - Nachlässe','',\n/" tree_items.js
sed -i '$s/$/\n],\n];/' tree_items.js

if [ "$DO_CLEANUP_TEMP" = "1" ]; then
    say "* clean up"
    rm -f tmp/*
fi

if [ "$DO_UPLOAD_FILES" = "1" ]; then
    say "* uploading files"
    scp -q tree_items.js webmaster@www:/export/www/htdocs/ibb/api/hantektonik/./
    echo ""
    echo "Testseiten (UB Website):"
    echo "  http://www.ub.unibas.ch/ibb/api/hantektonik/archiv-content.html"
    echo ""
fi

NOW=`date`
say "END: $NOW"
