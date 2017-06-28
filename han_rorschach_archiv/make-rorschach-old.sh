#!/bin/bash

# Rorschach Archiv
# generiere Tigra Tree Menu (lokal) aus Aleph Sequential
#
#
# Siehe auch output/aaa_liesmi
#
# history:
#   18.01.2010/ava portiert auf Hierarchie Toolbox
#   10.11.2011/osc manuell in tree_items.js oberste Stufe hinzufügen, um Anzeige zu optimieren
#   10.10.2014/ava rewrite nach Standard HAN-Format
#   12.01.2016/bmt anpassung an neues HAN-Format
#   28.06.2017/bmt anpassung: Datenquelle von aleph sequential anstelle AlephX

TARGET_FILE=`pwd`/output/tree_items.js
TARGET_HTML=`pwd`/output/index-content.html
HTB_DIR='/opt/bin/htb/'


DO_DOWNLOAD=1
DO_UPLOAD=1
DO_CLEANUP=1

echo '-------------------------'
echo 'UB Bern: Rorschach Archiv'
echo '-------------------------'

if [ "$DO_DOWNLOAD" == "1" ]; then
    say "* aktualisiere DSV05"
    cd $DSV05_DIR
    ./download-dsv05-sequential.sh
fi

    echo '* retrieve data with Aleph X-Services'
    $HTB_DIR/htb_alephx_store_set --ccl='wsl=rorschach' --file="tmp/rorschach-alephx.xml" --alephlib=dsv05

echo '* converting to MARC XML'
saxon9 -versionmsg:off -s:"tmp/rorschach-alephx.xml" \
    -xsl:"$HTB_DIR/alephxml_marcxml.xsl" \
    -o:"tmp/rorschach-marc.xml"

echo '* extracting hierarchy'
saxon9 -versionmsg:off -s:"tmp/rorschach-marc.xml" \
    -xsl:"$HTB_DIR/marcxml_hierarchy.xsl" \
    -o:"tmp/tmp"
$HTB_DIR/htb_build_hierarchy_bottom_up "tmp/tmp" "tmp/hierarchy.xml"

BACKUP=$TARGET_FILE.`date +'%Y%m%d'`
if [ ! -f $BACKUP ]; then
    echo '* backing up hierarchy'
    cp $TARGET_FILE $BACKUP
fi

echo '* formatting output'
saxon9 -versionmsg:off -s:"tmp/hierarchy.xml"  \
    -xsl:"$HTB_DIR/tigra_tree_menu.xsl" \
    -o:`pwd`/output/tree_items.js \
    MARCXML=`pwd`/tmp/rorschach-marc.xml \
    INFOXML=`pwd`/rorschach-info.xml \
    HTITLE=1

echo '* fixing punctuation'
perl -pi -e 's/<<//g;s/>>//g' "$TARGET_FILE"

if [ "$DO_CLEANUP" == "1" ]; then
    echo '* cleaning up'
    rm -f tmp/*
fi

if [ "$DO_UPLOAD" == "1" ]; then
    echo '* uploading file'
    scp $TARGET_FILE webmaster@www:/export/www/htdocs/ibb/api/rorschach/tree_items.js
    scp $TARGET_FILE webmaster@ub-webqm:/export/www/htdocs/ibb/api/rorschach/tree_items.js
    echo '* new version (installed):'
    echo '  http://www.ub.unibas.ch/ibb/api/rorschach/index-content.html' 
else
    echo '* new version (NOT installed):'
    echo "  file://$TARGET_HTML"
fi

echo "* aktualisiere HAN-Verbundtektonik"
# Die HAN-Verbundtektonik wird nicht von Grund auf neu generiert, sondern klebt nur die tree-items.js-Dateien der Einzelhierarchien zusammen.
sh ../han_tektonik/make-han.sh

echo 'done.'
