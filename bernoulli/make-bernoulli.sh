#!/bin/sh

# Bernoulli Edition:
# generiere Tigra Tree Menu fuer Bernoulli Korrespondenz
#
# Revision (21.09.2010 / andres.vonarx@unibas.ch)
# Inputpfad angepasst (13.12.2010 / oliver.schihin@unibas.ch)
# Anpassungen (22.08.2014 / oliver.schihin@unibas.ch)
# Anpassungen für Formatwechsel (04.01.2016 / basil.marti@unibas.ch)

HTB_ROOT=/intranet/ordnungssystem/1_Eigene-Organisation/15_IT/153_Bibliothekssysteme/bibtools/hierarchie_toolbox
DSV05=$HTB_ROOT/alephdata/dsv05.seq
DO_CLEANUP=0

echo '---------------------------'
echo 'UB Basel: Bernoulli Edition'
echo '---------------------------'

echo '* extrahiere Daten aus Aleph Sequential (dsv05: 909 $f bernoulli)'
perl $HTB_ROOT/htb/filter_alephseq.pl \
     --input=$DSV05 \
     --output=tmp/bernoulli.seq \
     --marctag='909 f' \
     --regex='bernoulli'

echo '* konvertiere in MARC XML'
$HTB_ROOT/htb/htb_alephseq_to_marcxml tmp/bernoulli.seq tmp/bernoulli-marc.xml

echo '* extrahiere Korrespondenten (830/903)'
saxon tmp/bernoulli-marc.xml bernoulli-hierarchy.xsl |sort -u > "tmp/tmp"
perl bernoulli-hierarchy.pl tmp/tmp > tmp/korrespondenz.xml

echo '* formatting output'
saxon tmp/korrespondenz.xml tigra_tree_menu_bernoulli.xsl > tree_items.js

if [ $DO_CLEANUP = 1 ]; then
    echo '* cleanup tmp files'
    rm -f tmp/*
fi

echo '* zum Publizieren:'
echo '  scp tree_items.js webmaster@www:/export/www/htdocs/ibb/api/bernoulli/tree_items.js'
echo ''
