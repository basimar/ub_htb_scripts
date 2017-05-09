#!/bin/bash

# bereite Spezialkatalogseiten auf
#
# installation:
#   chmod 755 make-fotojburckhardt.sh
# aufruf:
#   ./make-fotojburckhardt.sh
#
# 18.03.2013/abi
#

RWD=/export/www/htdocs/ibb/api/ubfotojburckhardt
TARGET_FILE='tree_items.js'
BIN_DIR='../htb'
HOME=`pwd`

if [ ! -f tmp/fotobur.xml ]
	then echo '!!! fotobur.xml nicht vorhanden !!!'
	echo 'Bitte download.sh lesen und ausfuehren, bevor dieses Skript gestartet wird!'
	exit
fi

echo '* loesche alte Dateien'
rm -f tmp/*.txt 2>/dev/null
rm -f tmp/*.js 2>/dev/null
rm -f tmp/hierarchy.xml 2>/dev/null

echo '* extracting hierarchy'
saxon9 -versionmsg:off -s:"tmp/fotobur.xml" -xsl:"$BIN_DIR/marcxml_hierarchy.xsl" -o:"tmp/tmp.txt"
$BIN_DIR/htb_build_hierarchy_bottom_up tmp/tmp.txt tmp/hierarchy.xml

echo '* formatting output'
saxon9 -versionmsg:off -s:"tmp/hierarchy.xml" -xsl:"$BIN_DIR/tigra_tree_menu.xsl" -o:"tmp/tree_tmp.js" MARCXML=$HOME/tmp/fotobur.xml ROOTNODE=0

echo '* getting DOIs'
saxon9 -versionmsg:off -s:"tmp/fotobur.xml" -xsl:"doilist.xsl" -o:"tmp/doi.txt"

echo '* fixing tree'
perl fixtree.perl

read -p '* auf ub-webqm.ub.unibas.ch installieren? [j/n] '
if [ "$REPLY" == "j" ]; then
		echo '* Upload JS auf ub-webqm'
		ssh webmaster@ub-webqm.ub.unibas.ch "cd $RWD && cp $TARGET_FILE $TARGET_FILE.backup"
		scp -q tmp/$TARGET_FILE webmaster@ub-webqm.ub.unibas.ch:$RWD
fi

read -p '* auf www.ub.unibas.ch installieren? [j/n] '
if [ "$REPLY" == "j" ]; then
		echo '* Upload JS auf www'
		ssh webmaster@ub-webvm.ub.unibas.ch "cd $RWD && cp $TARGET_FILE $TARGET_FILE.backup"
		scp -q tmp/$TARGET_FILE webmaster@ub-webvm.ub.unibas.ch:$RWD
fi

echo '* fertig'
