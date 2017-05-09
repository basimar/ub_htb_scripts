#!/bin/sh

# make-luzern.sh - bereite Daten auf für die Nachlässe von HAN Luzern
#
# History:
# 10.09.2010 andres.vonarx@unibas.ch
# 13.12.2010 oliver.schihin@unibas.ch (Inputpfad angepasst)
# 17.01.2011 osc (Auswahl für Schritt 2 Extraktion aus seq geändert zu Feld 852$b)
# 19.01.2011 osc (Löschen der Oberaufnahme ZB-Archiv mit sed, handgestrickte und provisorische Lösung)

DSV05='/home/htb/alephdata/dsv05.seq'
OUTDIR='output'
DO_CLEANUP=1

echo 'HAN Luzern'
echo '----------'
printf 'start: '
date

echo '* extrahiere Daten aus Aleph Sequential (dsv05: 852 $b LU ZHB Sondersammlung)'
perl ../htb/filter_alephseq.pl \
    --input=$DSV05 \
    --output=tmp/luzern.seq \
    --marctag='852 a' \
    --regex='LU ZHB Sondersammlung' \
#    --marctag='909 f' \
#    --regex='zhbna'


echo '* konvertiere in MARC XML'
../htb/htb_alephseq_to_marcxml tmp/luzern.seq tmp/luzern-marc.xml

echo '* extrahiere 490er'
../htb/htb_alephseq_extract_490 tmp/luzern.seq tmp/luzern.490

echo '* selektioniere Toplevel-Aufnahmen'
saxon9 -s:tmp/luzern-marc.xml -xsl:luzern-toplevel.xsl -o:tmp/toplevel_full.tmp

echo '* Lösche Oberaufnahme ZB Archiv'
sed /^000166456.*$/d tmp/toplevel_full.tmp >tmp/toplevel.tmp

echo '* mache Liste der Nachlässe A-Z'
perl luzern-a-bis-z-liste.pl

echo '* mache einzelne Treemenus:';
rm -f output/tree_*
perl luzern-treemenus.pl

echo '* zippe Output'
rm -f output/han_luzern.zip
zip -rqq output/han_luzern.zip output/*

#if [ $DO_CLEANUP = 1 ]; then
#    echo '* cleanup tmp files'
#    rm -f tmp/*
#fi

printf 'end: '
date
echo 'done.'
echo ''

