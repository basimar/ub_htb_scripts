#!/bin/bash

# Testen der Seite:
#   output/test.html
#
# HISTORY:
#   24.01.2013/ava: rev.
#   08.04.2013/osc: angepasst aleph v21, DO_INSTALL korrigiert
#   24.04.2014/ava: modif. Pfad
#   05.06.2014/ava: produziert auch Daten für SWA Firmen+Verbände
#   21.11.2014/ava: aleph v.22, kein Upload von ZZ_* Dateien
#   12.08.2016/ava: portiert auf ub-catmandu
# ---------------------------------------------------------------

# Schalter zum Aktivieren/Deaktivieren des Hochladens und Putzens
DO_INSTALL_PROD=1
DO_INSTALL_TEST=1
DO_CLEANUP=1

echo 'Generiere Webseiten für die SWA Sachdokumentation'
echo '-------------------------------------------------'
echo '* Dateien von Aleph herunterladen'
scp -q aleph@aleph.unibas.ch:/exlibris/aleph/u22_1/dsv01/scratch/pswabib.seq tmp/
scp -q aleph@aleph.unibas.ch:/exlibris/aleph/u22_1/dsv12/scratch/pswaaut.seq tmp/

echo '  Anzahl Aleph Records:'
printf "  BIB: "
grep -c ' FMT ' tmp/pswabib.seq
printf "  AUT:  "
grep -c ' FMT ' tmp/pswaaut.seq

echo '* flicke Zeichensatz'
perl /opt/bin/htb/fix_aleph_xml_charset.pl < tmp/pswabib.seq > tmp/tmp
awk 'NF' tmp/tmp > tmp/pswabib.seq
rm -f tmp/tmp
perl /opt/bin/htb/fix_aleph_xml_charset.pl < tmp/pswaaut.seq > tmp/tmp
awk 'NF' tmp/tmp > tmp/pswaaut.seq
rm -f tmp/tmp

echo '* konvertiere nach MARC21 XML';
/opt/bin/htb/htb_alephseq_to_marcxml tmp/pswabib.seq tmp/bib.xml
/opt/bin/htb/htb_alephseq_to_marcxml tmp/pswaaut.seq tmp/aut.xml

echo '* extrahiere relevante AUT + BIB Daten';
saxon tmp/bib.xml bib-extract.xsl > tmp/bib-extract.txt
saxon tmp/aut.xml aut-extract.xsl > tmp/aut-extract.txt

echo '* kombiniere AUT + BIB zu Strukturdatei'
perl swasd-hierarchie.pl > tmp/swasd-hierarchie.xml

echo '* extrahiere Hierarchie als Textdatei'
saxon tmp/swasd-hierarchie.xml swasd-descriptors.xsl > tmp/swasd-descriptors.txt

echo '* extrahiere Hierarchie (Firmen+Verbände)'
saxon tmp/swasd-hierarchie.xml swafv-descriptors.xsl > swafv/swafv-descriptors.txt

echo '* dokumentiere Thesaurus'
sed 's/ >.*$//' < tmp/swasd-descriptors.txt > doku-ezas/swa-sachdokumentation-deskriptoren.txt
saxon tmp/swasd-hierarchie.xml swasd-descriptors-doku.xsl > doku-ezas/swa-sachdokumentation-deskriptoren.xml
tidy -i -xml -utf8 -m doku-ezas/swa-sachdokumentation-deskriptoren.xml

saxon tmp/swasd-hierarchie.xml swasd-e-zas-flach.xsl \
    | sed 's/ /æææ/g' | sort -u  | sed 's/æææ/ /g' > doku-ezas/swa-e-zas-sachthemen-flach-unicode.txt
iconv -f utf8 -t windows-1252 doku-ezas/swa-e-zas-sachthemen-flach-unicode.txt > doku-ezas/swa-e-zas-sachthemen-flach-windows.txt
todos doku-ezas/swa-e-zas-sachthemen-flach-windows.txt

echo '* generiere Listen für E-Zeitschriftenarchiv'
export LC_COLLATE=de_CH.utf8
saxon tmp/swasd-hierarchie.xml swasd-e-zas-hierarchie.xsl > doku-ezas/swa-e-zas-sachthemen-hierarchie-unicode

echo '* generiere Tree Menu'
perl /opt/bin/htb/generate_treemenu_pro.pl \
    --in=tmp/swasd-descriptors.txt \
    --out=output/tree_items.js \
    --top='Systematische Gliederung' \
    --link  "'javascript:swasd(\\'%s\\')'"
perl -pi -e "s/°°°/\\\\',\\\\'/" output/tree_items.js

echo '* generiere Detailseiten'
rm -rf output/details/did*html
saxon9 -s:tmp/swasd-hierarchie.xml -xsl:swasd-detailseiten.xsl -o:tmp/detailseiten.html
tidy -m -utf8 -xml tmp/detailseiten.html
perl swasd-splitte-detailseiten.pl

echo '* generiere Detailseiten (Firmen+Verbände, ohne Geographica)'
saxon9 -s:tmp/swasd-hierarchie.xml -xsl:swafv-detailseiten.xsl -o:swafv/detailseiten.html
tidy -m -utf8 -xml swafv/detailseiten.html

echo '* generiere A-Z-Liste'
rm -rf output/index-?.html
saxon tmp/swasd-hierarchie.xml swasd-indexterms.xsl > tmp/indexterms.xml
saxon tmp/indexterms.xml swasd-index-az.xsl > tmp/indexterms.txt
perl swasd-index-az.pl

echo '* generiere Wortindex für Suchmaschine'
saxon tmp/indexterms.xml swasd-suchmaschine.xsl > tmp/suchmaschine.tmp
perl swasd-suchmaschine.pl

echo '* generiere A-Z-Liste für Suchmaschine (Firmen+Verbände)'
saxon tmp/swasd-hierarchie.xml swafv-indexterms.xsl > tmp/indexterms-fv.xml
saxon tmp/indexterms-fv.xml swasd-index-az.xsl > swafv/indexterms.txt

echo '* generiere Wortindex für Suchmaschine (Firmen+Verbände)'
saxon tmp/indexterms-fv.xml swasd-suchmaschine.xsl > swafv/suchmaschine_deskriptoren.tmp

echo '* Outputdateien zippen und hochladen'
cd output
rm -f swasd.zip
zip -q swasd.zip * -x \*ZZ_*.txt
zip -q swasd.zip details/* -x \*ZZ_*.txt
cd ..
ssh webmaster@ub-webqm.ub.unibas.ch 'cd /export/www/htdocs/ibb/api/swasd && cp swasd.zip swasd.zip.backup'
ssh webmaster@ub2.unibas.ch 'cd /export/www/htdocs/ibb/api/swasd && cp swasd.zip swasd.zip.backup'
scp -q output/swasd.zip webmaster@ub-webqm.ub.unibas.ch:/export/www/htdocs/ibb/api/swasd
scp -q output/swasd.zip webmaster@ub2.unibas.ch:/export/www/htdocs/ibb/api/swasd

if [ $DO_INSTALL_TEST == 1 ]; then
    echo '* installiere Seiten auf Webserver (Test)'
    ssh webmaster@ub-webqm 'cd /export/www/htdocs/ibb/api/swasd && rm -f details/did* && unzip -oqq swasd.zip'
    ssh webmaster@ub-webqm 'find /export/www/htdocs/ibb/api/swasd -type f -exec chmod 644 {} \;'
    ssh webmaster@ub-webqm 'find /export/www/htdocs/ibb/api/swasd -type d -exec chmod 755 {} \;'
    scp -q tmp/suchmaschine.txt webmaster@ub-webqm:/export/www/cgi-bin/index/data/index_swasd
fi

if [ $DO_INSTALL_PROD == 1 ]; then
    echo '* installiere Seiten auf Webserver (Produktion)'
    ssh webmaster@ub-webvm 'cd /export/www/htdocs/ibb/api/swasd && rm -f details/did* && unzip -oqq swasd.zip'
    ssh webmaster@ub-webvm 'find /export/www/htdocs/ibb/api/swasd -type f -exec chmod 644 {} \;'
    ssh webmaster@ub-webvm 'find /export/www/htdocs/ibb/api/swasd -type d -exec chmod 755 {} \;'
    scp -q tmp/suchmaschine.txt webmaster@www:/export/www/cgi-bin/index/data/index_swasd
fi

if [ $DO_CLEANUP == 1 ]; then
    echo '* cleanup tmp files'
    rm -f tmp/[^ZZ]*
fi

printf 'fertig: '
date +'%d. %B %Y, %T'
echo ''
