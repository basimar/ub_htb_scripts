#!/bin/bash

# make-firmen-und-verbaende.sh
# Doku siehe ANLE_SWA_Firmen_und_Verbaende_aufbereiten_20140604_ava.html
# http://ub-files.ub.unibas.ch/ordnungssystem/1_Eigene-Organisation/15_IT/153_Bibliothekssysteme/bibtools/hierarchie_toolbox/swa_firmen_und_verbaende/ANLE_SWA_Firmen_und_Verbaende_aufbereiten_20140604_ava.html
#
# history
# rev. 13.05.2016 andres.vonarx@unibas.ch
# 10.08.2016 portiert auf ub-catmandu


# Schalter zum Aktivieren/Deaktivieren des Hochladens und Putzens
DO_INSTALL_TEST=1
DO_INSTALL_PROD=1
DO_CLEANUP=1

echo "SWA Firmen und Verbände: Webseiten aufbauen"
echo "-------------------------------------------"
date

echo "* Aleph Daten downloaden"
rm -f tmp/swa-doksf.seq
#ssh aleph@aleph.unibas.ch ls -e /exlibris/aleph/u22_1/dsv01/scratch/swa-doksf.seq |awk '{print "  Daten vom " $7,$6,$9,$8}'
scp -q aleph@aleph.unibas.ch:/exlibris/aleph/u22_1/dsv01/scratch/swa-doksf.seq tmp

if [ ! -f tmp/swa-doksf.seq ]; then
    echo "Aleph-Datei swa-doksf.seq konte nicht heruntergeladen werden."
    echo "PROGRAMM ABGEBROCHEN."
    exit
fi

echo "* Qualitäts-Check"
grep ' 71[01]  ' tmp/swa-doksf.seq > kss-lookup-errors.txt

echo "* Konkordanz Deskriptoren / Körperschaften"
perl bin/extract-firmen-deskriptoren.pl
sort -u < tmp/kss-desk.tmp > tmp/kss-desk.txt

echo "* Extrahiere Körperschaften"
awk -F'|' '{print $2 "|" $3}' < tmp/kss-desk.txt | sort -u > tmp/kss-aut.txt

echo "* Geographische Unterschlagwörter extrahieren"
grep '\$\$z' tmp/kss-desk.txt | perl -p -e "s/\|.*$//" | sort -u > tmp/desk-geographica.txt

echo "* Branchen-Systematik mit Geographica anreichern"
echo "  [Anmerkung: nur Geographica, die in den doksf-Daten vorkommen.]"
perl bin/add-geographica-to-descriptors.pl

echo "* Tree Menu generieren"
perl /opt/bin/htb/generate_treemenu_pro.pl \
    --in=tmp/swafv-descriptors-plus.txt \
    --out=output/tree_items.js \
    --top='Systematische Gliederung' \
    --link  "'javascript:swafv(\\'%s\\')'"
perl -pi -e "s/°°°/\\\\',\\\\'/" output/tree_items.js

echo "* Detailseiten aufbereiten"
echo "  (bitte 5 Minuten Geduld...)"
rm -f output/details/did*.html
perl bin/swafv-splitte-detailseiten.pl

echo "* generiere Wortindex (Deskriptoren)"
perl bin/suchmaschine-swafv-desk.pl

echo "* generiere Wortindex (Körperschaften)"
perl bin/suchmaschine-swafv-kss.pl

echo "* generiere A-Z Liste"
perl bin/swafv-index-az.pl

echo "* Outputdateien zippen und hochladen"
cd output
rm -f swafv.zip
zip -q -r swafv.zip * -x \*ZZ_*.txt
cd ..
ssh webmaster@ub-webqm.ub.unibas.ch 'cd /export/www/htdocs/ibb/api/swafv && cp swafv.zip swafv.zip.backup'
ssh webmaster@ub-webvm.ub.unibas.ch 'cd /export/www/htdocs/ibb/api/swafv && cp swafv.zip swafv.zip.backup'
scp -q output/swafv.zip webmaster@ub-webqm.ub.unibas.ch:/export/www/htdocs/ibb/api/swafv
scp -q output/swafv.zip webmaster@ub-webvm.ub.unibas.ch:/export/www/htdocs/ibb/api/swafv

if [ $DO_INSTALL_TEST == 1 ]; then
    echo "* installiere Webseiten auf Webserver (TEST)"
    ssh webmaster@ub-webqm 'cd /export/www/htdocs/ibb/api/swafv && rm -f details/did* && unzip -oqq swafv.zip'
    ssh webmaster@ub-webqm 'find /export/www/htdocs/ibb/api/swafv -type f -exec chmod 644 {} \;'
    ssh webmaster@ub-webqm 'find /export/www/htdocs/ibb/api/swafv -type d -exec chmod 755 {} \;'
    
    echo "* installiere Wortindex (Deskriptoren) auf Webserver (TEST)"
    scp -q tmp/index_swafv_desk webmaster@ub-webqm:/export/www/cgi-bin/index/data/./

    echo "* installiere Wortindex (Körperschaften) auf Webserver (TEST)"
    scp -q tmp/index_swafv_kss  webmaster@ub-webqm:/export/www/cgi-bin/index/data/./
fi

if [ $DO_INSTALL_PROD == 1 ]; then
    echo "* installiere Webseiten auf Webserver (PROD)"
    ssh webmaster@ub-webvm 'cd /export/www/htdocs/ibb/api/swafv && rm -f details/did* && unzip -oqq swafv.zip'
    ssh webmaster@ub-webvm 'find /export/www/htdocs/ibb/api/swafv -type f -exec chmod 644 {} \;'
    ssh webmaster@ub-webvm 'find /export/www/htdocs/ibb/api/swafv -type d -exec chmod 755 {} \;'
    
    echo "* installiere Wortindex (Deskriptoren) auf Webserver (PROD)"
    scp -q tmp/index_swafv_desk webmaster@ub-webvm:/export/www/cgi-bin/index/data/./

    echo "* installiere Wortindex (Körperschaften) auf Webserver (PROD)"
    scp -q tmp/index_swafv_kss  webmaster@ub-webvm:/export/www/cgi-bin/index/data/./
fi

if [ $DO_CLEANUP == 1 ]; then
    echo "* temporäre Dateien löschen"
    rm -f tmp/[a-z]*
fi

if [ -s kss-lookup-errors.txt ]; then
    echo "ACHTUNG: Körperschaften ohne GND gefunden."
else
    rm -f kss-lookup-errors.txt
    echo "Alle Körperschaften sind GND-kontrolliert."
fi

date
echo "fertig."
