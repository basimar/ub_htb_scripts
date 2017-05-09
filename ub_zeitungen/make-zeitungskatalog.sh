#!/bin/bash

# make-zeitungskatalog.sh
# generiere Seiten fuer Zeitungskatalog UB Web
#   http://www.ub.unibas.ch/cmsdata/spezialkataloge/zeitungen/zeitungen_a_bis_z.html 
#   http://www.ub.unibas.ch/cmsdata/spezialkataloge/zeitungen/zeitungen_historisch_ausland.html
#   http://www.ub.unibas.ch/cmsdata/spezialkataloge/zeitungen/zeitungen_historisch_basel.html
#   http://www.ub.unibas.ch/cmsdata/spezialkataloge/zeitungen/zeitungen_historisch_schweiz.html
#   http://www.ub.unibas.ch/cmsdata/spezialkataloge/zeitungen/zeitungen_nach_laendern.html
#
# 17.05.2011/ava

DO_DOWNLOAD=1
DO_INSTALL=1
DO_CLEANUP=1

HTB=/intranet/ordnungssystem/1_Eigene-Organisation/15_IT/153_Bibliothekssysteme/bibtools/hierarchie_toolbox/htb

echo ''
echo 'Zeitungen im Raum Basel'
echo '-----------------------'

if [ $DO_DOWNLOAD = 1 ]; then
    echo '* hole Daten von Aleph X-Server'
    alephx_store_set --ccl="wlc=ztgbs" --file="tmp/ztgbs.tmp"
fi

echo '* konvertiere Daten nach MARC21'
saxon "tmp/ztgbs.tmp" "$HTB/alephxml_marcxml.xsl" > "tmp/ztgbs.xml"

echo '* extrahiere Information'
saxon "tmp/ztgbs.xml" zeitungskatalog.xsl > "tmp/ztgbs.txt"

echo '* schreibe HTML-Seiten (iframes)'
perl zeitungskatalog.pl

if [ $DO_INSTALL = 1 ]; then
    echo '* installiere Webseiten auf Webserver'
    scp -q tmp/zeitungen*html webmaster@ub-webqm:/export/www/htdocs/cmsdata/spezialkataloge/zeitungen/./
    scp -q tmp/zeitungen*html webmaster@www:/export/www/htdocs/cmsdata/spezialkataloge/zeitungen/./
fi

if [ $DO_CLEANUP = 1 ]; then
    echo '* lösche temporäre Daten'
    rm -f tmp/*
fi

echo 'fertig.'
