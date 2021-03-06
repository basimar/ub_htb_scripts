#!/bin/bash

echo 'Systematik UB Lesesaal'

inputfile='klassifikation-lesesaalub.txt'
targetdir='/export/www/htdocs/ibb/api/ublesesaal'

backupfile=`perl -MPOSIX -e 'print strftime("tree_items.js.%Y%m%d",localtime)'`
if [[ -f tree_items.js && ! -f $backupfile ]]; then
    echo '* backup alte Version'
    cp tree_items.js $backupfile
fi

echo '* generiere tree_items.js'
perl ../htb/generate_treemenu_pro.pl \
    --in    $inputfile \
    --out   tree_items.js \
    --link  "'javascript:sig(\\'%s\\')'" \
    --top   'Systematik UB Lesesaal'

if [ $? != 0 ]; then
    echo 'Programm abgebrochen.'
    exit;
fi

read -p '* auf ub-webqm.ub.unibas.ch installieren? [j/n] '
if [ "$REPLY" == "j" ]; then
    scp tree_items.js webmaster@ub-webqm.ub.unibas.ch:$targetdir
fi

read -p '* auf www.ub.unibas.ch installieren? [j/n] '
if [ "$REPLY" == "j" ]; then
    scp tree_items.js webmaster@ub2.unibas.ch:$targetdir
fi

echo '* fertig.'
echo '* Resultat siehe:'
echo http://ub-webqm.ub.unibas.ch/ub-hauptbibliothek/recherche/kataloge/lesesaal-systematik/
echo http://ub2.unibas.ch/ub-hauptbibliothek/recherche/kataloge/lesesaal-systematik/


