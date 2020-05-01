#!/bin/bash

# -----------------------------------------------
# UB Privatarchive/Nachlaesse
# -----------------------------------------------
# usage:
#
# history:
#   00.00.2009 - Aleph V.18/ava
#   16.04.2010 - Aleph V.20/ava
#   03.08.2010 - Umgehung von Problemen mit java heap space
#   14.03.2011 - Anpassung an neue Hash-Marker (osc)
#   15.03.2013 - Aleph V.21/ava
#   08.05.2014 - Aleph V.22/ava
#   18.02.2015 - Versteckte Katalogisate werden nun vollstaendig aus der Hierarchie entfernt/bmt
#   10.10.2016 - Zügeln nach ub-catmandu
#
# caveat:
#   Solaris "sed" kann kein "-i". Gebrauche stattdessen "perl -pi -e"
#

QUIET=0
ZIP=1
CLEANUP=1
INSTALL=1
ANZAHL_DATEIEN_SOLL=25
ERROR_MAILTO="basil.marti@unibas.ch"

# ---------------------------------------
# Dateien und Verzeichnisse
# ---------------------------------------

# -- auf aleph.unibas.ch
DSV05_URL=http://aleph.unibas.ch/dirlist/u/dsv05/scratch/dsv05.seq

# -- auf dem lokalen host
BIN_DIR=/opt/bin/htb
HOME_DIR=/opt/scripts/htb/ub_nachlass
DSV05_SEQ_ALL=/opt/scripts/htb/ub_nachlass/dsv05/dsv05.seq.all
DSV05_SEQ_HIDE=/opt/scripts/htb/ub_nachlass/dsv05/dsv05.seq.hide
DSV05_490=/opt/scripts/htb/ub_nachlass/dsv05/dsv05.490
DSV05_490_HIDE=/opt/scripts/htb/ub_nachlass/dsv05/dsv05.490.hide
DSV05_490_ALL=/opt/scripts/htb/ub_nachlass/dsv05/dsv05.490.all

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
cd $HOME_DIR
say '-----------------------------------------------------'
say 'UB Basel: Privatarchive/Nachlaesse/Autographensammlung'
say '-----------------------------------------------------'
NOW=`date`
say "Start: $NOW"

# ----------------------------------------------------------
# PHASE 1: Die Ausgangsdateien werden aufbereitet
# - MARC XML Datei
# - Hierarchie.XML
# ----------------------------------------------------------
if [ ! -d tmp/marc ]; then mkdir tmp/marc; fi

# dsv05.seq ist ein Dump von DSV05 im Format Aleph Sequential.
# Die Datei wird per job_list periodisch erstellt (taeglich 23:00).
say '* aktualisiere dsv05.seq'
wget --quiet --http-user=ids --http-passwd=ids --output-document="$DSV05_SEQ_ALL" "$DSV05_URL"
if [ $? -ne 0 ]; then
    say '! Fehler beim Download. Programm abgebrochen.'
    exit
fi

say '* Finde versteckte Katalogisate'
#Katalogsate mit hide_this sollen in der Hierarchie nicht angezeigt werden.
perl $BIN_DIR/filter_alephseq.pl --in=$DSV05_SEQ_ALL --out=$DSV05_SEQ_HIDE --marc='909 f' --regex='hide_this' --noignorecase

# dsv05.490 ist ein Auszug der 490er Felder
say '* extrahiere 490er'
"$BIN_DIR/htb_alephseq_extract_490" "$DSV05_SEQ_ALL" "$DSV05_490_ALL"
"$BIN_DIR/htb_alephseq_extract_490" "$DSV05_SEQ_HIDE" "$DSV05_490_HIDE"

say "* Entferne versteckte Katalogisate"
cat $DSV05_490_ALL $DSV05_490_HIDE | sort -r | uniq -u > $DSV05_490 

say '* hole Toplevel-Aufnahmen von Aleph'
# Anmerkung zur Selektion der Toplevel Aufnahmen
# 909 $f
#    ubnl1  = Privatarchive/Nachlaesse. Personen
#    ubnl2  = Privatarchive/Nachlaesse. Koerperschaften
#    ubaut1 = Autographensammlungen
# 909 $f "hide_this" wird als zwei Woerter indexiert, deshalb
#   verwenden wir in der CCL Suchstring "hide".
#   Dateien mit diesem Code sind vor dem WWW-User verborgen
#   (siehe Profil "ALEPH"), nicht aber vor dem X-Service User.
# Known bug:
#   -- die Toplevel XML-Datei enthaelt *keine* "909 $f hide_this"
#   -- die dsv05.seq enthaelt sehr wohl 909 $f "hide_this"
#      (falls noetig, muss hier noch ein Filter eingebaut werden.)
# Filter eingebaut, Bug behoben 18.02.2015/bmt
"$BIN_DIR/htb_alephx_store_set" --quiet --ccl='wco=ubnl1  not wco=hide' --file=tmp/p-top-oai.xml --alephlib=dsv05
"$BIN_DIR/htb_alephx_store_set" --quiet --ccl='wco=ubnl2  not wco=hide' --file=tmp/k-top-oai.xml --alephlib=dsv05
"$BIN_DIR/htb_alephx_store_set" --quiet --ccl='wco=ubaut1 not wco=hide' --file=tmp/a-top-oai.xml --alephlib=dsv05

say '* konvertiere Toplevel nach MARC'
saxon9 -s:tmp/p-top-oai.xml -xsl:"$BIN_DIR/alephxml_marcxml.xsl" -o:tmp/p-top-marc.xml
saxon9 -s:tmp/k-top-oai.xml -xsl:"$BIN_DIR/alephxml_marcxml.xsl" -o:tmp/k-top-marc.xml
saxon9 -s:tmp/a-top-oai.xml -xsl:"$BIN_DIR/alephxml_marcxml.xsl" -o:tmp/a-top-marc.xml

say '* extrahiere Toplevel Informationen in Textdatei'
saxon9 -s:tmp/p-top-marc.xml -xsl:extract-top-info.xsl -o:tmp/p-toplist.txt
saxon9 -s:tmp/k-top-marc.xml -xsl:extract-top-info.xsl -o:tmp/k-toplist.txt
saxon9 -s:tmp/a-top-marc.xml -xsl:extract-top-info.xsl -o:tmp/a-toplist.txt
perl -pi -e 's/(<<|>>)//g' tmp/p-toplist.txt
perl -pi -e 's/(<<|>>)//g' tmp/k-toplist.txt
perl -pi -e 's/(<<|>>)//g' tmp/a-toplist.txt

say '* generiere top-down Hierarchie (aus Toplevel und 490er)'
perl $BIN_DIR/htb_build_hierarchy_top_down_MIT_KRYPTONACHLASS --toplist=tmp/p-toplist.txt --list490="$DSV05_490" --outfile=tmp/p-hierarchy.xml
perl $BIN_DIR/htb_build_hierarchy_top_down_MIT_KRYPTONACHLASS --toplist=tmp/k-toplist.txt --list490="$DSV05_490" --outfile=tmp/k-hierarchy.xml
perl $BIN_DIR/htb_build_hierarchy_top_down_MIT_KRYPTONACHLASS --toplist=tmp/a-toplist.txt --list490="$DSV05_490" --outfile=tmp/a-hierarchy.xml

say '* fixe Systemnummern aller Nachlaesse, schneide weg den Hash-Marker'
perl -pi -e 's/recno="\d*[KN]/recno="/' tmp/p-hierarchy.xml
perl -pi -e 's/recno="\d*[KN]/recno="/' tmp/k-hierarchy.xml
perl -pi -e 's/recno="\d*[KN]/recno="/' tmp/a-hierarchy.xml

say '* mache eine Liste aller verwendeten Systemnummern'
saxon9 -s:tmp/p-hierarchy.xml -xsl:"$BIN_DIR/extract-recno-from-hierarchy.xsl" -o:tmp/p-nummernliste.txt
saxon9 -s:tmp/k-hierarchy.xml -xsl:"$BIN_DIR/extract-recno-from-hierarchy.xsl" -o:tmp/k-nummernliste.txt
saxon9 -s:tmp/a-hierarchy.xml -xsl:"$BIN_DIR/extract-recno-from-hierarchy.xsl" -o:tmp/a-nummernliste.txt

say '* generiere einzelne MARC21 XML Dateien fuer verwendete Records'
# XSLT ist nicht perfomant mit der ganzen DSV05.
# Wir machen daher eine XML-Datei fuer jeden Record, der tatsaechlich gebraucht wird
"$BIN_DIR/htb_alephseq_numberlist_to_multiple_marcxml" --alephseq="$DSV05_SEQ_ALL" --numberlist=tmp/p-nummernliste.txt --outputdir=tmp/marc
"$BIN_DIR/htb_alephseq_numberlist_to_multiple_marcxml" --alephseq="$DSV05_SEQ_ALL" --numberlist=tmp/k-nummernliste.txt --outputdir=tmp/marc
"$BIN_DIR/htb_alephseq_numberlist_to_multiple_marcxml" --alephseq="$DSV05_SEQ_ALL" --numberlist=tmp/a-nummernliste.txt --outputdir=tmp/marc

say '* reichere Hierarchie XML mit MARC Info an'
perl enrich-hierarchy-with-marcdata.pl --infile="tmp/p-hierarchy.xml" --outfile="tmp/p-hierarchy2.xml" --marcdir="tmp/marc"
perl enrich-hierarchy-with-marcdata.pl --infile="tmp/k-hierarchy.xml" --outfile="tmp/k-hierarchy2.xml" --marcdir="tmp/marc"
perl enrich-hierarchy-with-marcdata.pl --infile="tmp/a-hierarchy.xml" --outfile="tmp/a-hierarchy2.xml" --marcdir="tmp/marc"

# ----------------------------------------------------------
# PHASE 2: HTML Seiten formatieren
# ----------------------------------------------------------
say '* generiere Indexseiten'
saxon9 -s:"tmp/p-hierarchy.xml" -xsl:hierarchie_zu_text.xsl -o:"tmp/p-info.txt"
saxon9 -s:"tmp/k-hierarchy.xml" -xsl:hierarchie_zu_text.xsl -o:"tmp/k-info.txt"
saxon9 -s:"tmp/a-hierarchy.xml" -xsl:hierarchie_zu_text.xsl -o:"tmp/a-info.txt"

perl indexseiten.pl --infile="tmp/p-info.txt" --outfile="target/index-content-p.html" --az
perl indexseiten.pl --infile="tmp/k-info.txt" --outfile="target/index-content-k.html"
perl indexseiten.pl --infile="tmp/a-info.txt" --outfile="target/index-content-a.html"

say '* generiere Indexseiten fuer Robots'
perl indexseiten-fuer-robots.pl --infile="tmp/p-info.txt" --outfile="target/personen_robots.html"
perl indexseiten-fuer-robots.pl --infile="tmp/k-info.txt" --outfile="target/koerperschaften_robots.html"
perl indexseiten-fuer-robots.pl --infile="tmp/a-info.txt" --outfile="target/autographen_robots.html"

say '* loesche alte Detail-Seiten'
rm -f "target"/d0*.html

say '* generiere Detail-Seiten'
saxon9 -s:tmp/p-hierarchy2.xml -xsl:tigra_tree_menu_split.xsl -o:tmp/p-split.txt MARCDIR=tmp/marc
saxon9 -s:tmp/k-hierarchy2.xml -xsl:tigra_tree_menu_split.xsl -o:tmp/k-split.txt MARCDIR=tmp/marc
saxon9 -s:tmp/a-hierarchy2.xml -xsl:tigra_tree_menu_split.xsl -o:tmp/a-split.txt MARCDIR=tmp/marc

perl -pi -e 's/<<//g;s/>>//g' "tmp/p-split.txt"
perl -pi -e 's/<<//g;s/>>//g' "tmp/k-split.txt"
perl -pi -e 's/<<//g;s/>>//g' "tmp/a-split.txt"

perl detailseiten.pl --infile="tmp/p-split.txt" --outdir="target" --template="template_detail_pages.html" --backlink="index-content-p.html"
perl detailseiten.pl --infile="tmp/k-split.txt" --outdir="target" --template="template_detail_pages.html" --backlink="index-content-k.html"
perl detailseiten.pl --infile="tmp/a-split.txt" --outdir="target" --template="template_detail_pages.html" --backlink="index-content-a.html"

# ----------------------------------------------------------
# PHASE 3: Plausibiltaetspruefung
# ----------------------------------------------------------
ANZAHL_DATEIEN_IST=`ls -1 tmp |wc -l |awk '{print $1}'`
if [ "$ANZAHL_DATEIEN_IST" != "$ANZAHL_DATEIEN_SOLL" ]; then
  ( echo "make-ubnachlass.pl: unerwartete Anzahl Outputdateien."; echo "Details siehe:"; echo "http://alephtest.unibas.ch/dirlist/u/local/andres/spezkat/spezkat.log" ) | mailx -s "Fehler in make-ubnachlass.pl" $ERROR_MAILTO
  say "* unerwartete Anzahl Outputdateien. Programm abgebrochen."
  NOW=`date`
  say "Ende: $NOW"
  exit 0
fi

if [ "$ZIP" == "1" ]; then
  say "* generiere ZIP-File"
  zip -jq "target/ubnachlass.zip" "target/"*
  say "* backup remote ZIP File"
  ssh webmaster@ub2.unibas.ch 'cd /export/www/htdocs/ibb/api/ubnachlass && cp ubnachlass.zip ubnachlass.zip.backup'
  say "* kopiere ZIP File"
  scp -q "target/ubnachlass.zip" webmaster@ub2.unibas.ch:/export/www/htdocs/ibb/api/ubnachlass
fi

if [ "$CLEANUP" == "1" ]; then
  say "* putze temporaere Dateien"
  rm -f "tmp"/?-*
  rm -fr "tmp/marc"
fi

# ----------------------------------------------------------
# PHASE 4: HTML Seiten uploaden und installieren
# ----------------------------------------------------------
if [ "$INSTALL" == "1" ]; then
    say '* installiere Dateien auf Webserver (www)'
    ssh webmaster@ub2.unibas.ch 'cd /export/www/htdocs/ibb/api/ubnachlass && rm -f d0* && unzip -oqq ubnachlass.zip'
fi

if [ "$QUIET" != "1" ]; then
    echo ""
    echo "* Statistik:"
    cd target
    grep -c detail *robots.html | sed 's/_robots.html:/ /g'
    echo ""
fi

NOW=`date`
say "Ende: $NOW"
