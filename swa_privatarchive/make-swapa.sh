#!/bin/sh

# make-swapa.sh
# bereite Daten auf für die SWA Privatarchive
# http://www.ub.unibas.ch/ub-wirtschaft-swa/schweiz-wirtschaftsarchiv/privatarchive/
#
# usage:
#   $ ./make-swapa.sh
#
# Laufzeit
#   ca. 2 Stunden
#
# ACHTUNG:
# - siehe aa_liesmi.html
#
# History:
#   24.08.2010  V.1/ava
#   30.03.2011  angepasst fuer Publishing auf /intranet
#   10.06.2013  angepasst auf neue Location im Ordnungssystem
#   23.05.2014  Pfade angepasst / osc
#   26.03.2018  Umbau, damit auch untergeordnete Aufnahmen angezeigt werden (analog zu UB NL) / bmt

# ---------------------------------------
# Funktionen
# ---------------------------------------
# Ausgabe auf Bildschirm (laesst sich unterdruecken mit QUIET=1)
say () { 
    if [ "$QUIET" != "1" ]; then echo "$1"; fi
}

# ---------------------------------------
# Hauptprogramm
# ---------------------------------------

if [ ! -f swapa-dsv05-oberbegriffe-schlagwoerter.csv ]; then
    echo Kann swapa-dsv05-oberbegriffe-schlagwoerter.csv nicht mehr finden.
    echo Programm abgebrochen.
    exit
fi
DSV05=/opt/data/dsv05/dsv05.seq
BIN_DIR=/opt/bin/htb/
HOME_DIR=/opt/scripts/htb/swa_privatarchive

DSV05_490_ALL=/opt/scripts/htb/swa_privatarchive/dsv05/dsv05.490.all

QUIT=0
DO_INSTALL=1
DO_CLEANUP=1

# ---------------------------------------
# Hauptprogramm
# ---------------------------------------

cd $HOME_DIR
say '-----------------------------------------------------'
say 'UB Wirtschaft: SWA Privatarchive'
say '-----------------------------------------------------'
NOW=`date`
say "Start: $NOW"

cd $HOME_DIR

say "* Extrahiere SWA-Bestandesaufnahmen aus dsv05.seq"
perl $BIN_DIR/filter_alephseq.pl \
    --input=$DSV05 \
    --output=tmp/swapa.seq \
    --marctag='909 f' \
    --regex='swapa*'

say '* Konvertiere in MARC XML'
$BIN_DIR/htb_alephseq_to_marcxml tmp/swapa.seq tmp/swapa-marc.xml

say "* Extrahiere SWA-Aufnahmen aus dsv05.seq"
perl $BIN_DIR/filter_alephseq.pl \
    --input=$DSV05 \
    --output=tmp/swapa-full.seq \
    --marctag='852 a' \
    --regex='Basel UB Wirtschaft*'

say '* Konvertiere in MARC XML'
$BIN_DIR/htb_alephseq_to_marcxml tmp/swapa-full.seq tmp/swapa-marc-full.xml

say '* Generiere Schlagwort-Struktur'
perl  swapa-strukturiere-schlagwoerter.pl
# Aus irgendeinem Grund produziert swapa-strukturiere-schlagwoerter.pl kein UTF8 mehr, die produzierte Datei wird deshalb manuell mit iconv konvertiert.
iconv -f ISO-8859-1 -t UTF-8 tmp/swapa-schlagwoerter.xml > tmp/swapa-schlagwoerter-utf8.xml

echo '* Generiere Hierarchie'
saxon tmp/swapa-schlagwoerter-utf8.xml swapa-hierarchie.xsl > tmp/swapa-hierarchie.txt

#say "* Reichere Hierarchie mit untergeordneten Aufnahmen an"
#perl swapa-hierarchie-topdown.pl tmp/swapa-full.seq tmp/swapa-hierarchie.txt tmp/swapa-hierarchie-full.txt

echo '* generiere Tree Menu'
perl $BIN_DIR/generate_treemenu_pro.pl \
    --in    tmp/swapa-hierarchie-full.txt \
    --out   tmp/tree_items.js \
    --link  "'javascript:swapa(\\'%s\\')'" \
    --top   'Systematische Gliederung'

echo '* fixe Tree Menu'
perl swapa-fix-treemenu.pl

echo '* baue Index für Suchmaschine'
saxon9 -s:tmp/swapa-marc-full.xml -xsl:swapa-suchmaschine.xsl > tmp/index_swapa

if [ $DO_INSTALL = 1 ]; then
    echo '* installiere Treemenu auf Webserver'
    scp -q tmp/tree_items.js webmaster@ub-webqm:/export/www/htdocs/ibb/api/swapa/./
    scp -q tmp/tree_items.js webmaster@www:/export/www/htdocs/ibb/api/swapa/./
    echo '* installiere Wortindex auf Webserver'
    scp -q tmp/index_swapa webmaster@ub-webqm:/export/www/cgi-bin/index/data/./
    scp -q tmp/index_swapa webmaster@www:/export/www/cgi-bin/index/data/./
fi

if [ $DO_CLEANUP = 1 ]; then
    echo '* cleanup tmp files'
    rm -f tmp/*
fi

echo '* aktualisiere HAN-Verbundtektonik'
# Die HAN-Verbundtektonik wird nicht von Grund auf neu generiert, sondern klebt nur die tree-items.js-Dateien der Einzelhierarchien zusammen.
sh ../han_tektonik/make-han.sh
