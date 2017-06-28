#!/bin/sh

# Archive REBUS
# generiere Tigra Tree Menu aus Aleph X-Services
# 06.06.2006/andres.vonarx@unibas.ch
# 12.01.2016/basil.marti@unibas.ch :: Anpassung an neues HAN-Format

TARGET_FILE='tree_items.js'
BIN_DIR='/opt/bin/htb/'

backup_file () {
    # backup a file, provided it exists and no backup exists yet
    if [ ! -z "$1" -a -f "$1" ]; then
        backup_extension=`perl -MPOSIX -e 'print strftime(".%Y%m%d",localtime)'`$USER
        backup_filename="$1$backup_extension"
        if [ ! -f $backup_filename ]; then
            echo "* backup $1"
            cp "$1" "$backup_filename"
        fi
    fi
}

echo '---------------------'
echo 'UB Bern: Rebus Archiv'
echo '---------------------'

backup_file tree_items.js;

echo '* retrieve data with Aleph X-Services'
$BIN_DIR/htb_alephx_store_set --quiet --ccl='wcl=rebus' --file="tmp/rebus-alephx.xml" --alephlib=dsv05

echo '* converting to MARC XML'
saxon9 -versionmsg:off -s:"tmp/rebus-alephx.xml" -xsl:"$BIN_DIR/alephxml_marcxml.xsl"  -o:"tmp/rebus-marc.xml"

echo '* extracting hierarchy'
saxon9 -versionmsg:off -s:"tmp/rebus-marc.xml" -xsl:"$BIN_DIR/marcxml_hierarchy.xsl" -o:"tmp/tmp"
$BIN_DIR/htb_build_hierarchy_bottom_up "tmp/tmp" "tmp/hierarchy.xml"

echo '* formatting output'
saxon9 -versionmsg:off -s:"tmp/hierarchy.xml" -xsl:"$BIN_DIR/tigra_tree_menu.xsl" -o:tree_items.js MARCXML=`pwd`/tmp/rebus-marc.xml ROOTNODE=0

echo '* fixing punctuation'
perl -pi -e 's/<</[/g;s/>>/]/g' tree_items.js

echo '* cleaning up'
rm -f tmp/*

echo
echo '* zum Uploaden:'
echo "   scp tree_items.js webmaster@www:/export/www/htdocs/ibb/api/rebus/tree_items.js"
echo
echo '* Ziel:'
echo '   http://www.ub.unibas.ch/ibb/api/rebus/'
echo
echo 'done.'
