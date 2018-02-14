#!/bin/bash

# make-han.sh
# Generiert alle HAN-Hierarchien neu
# --------------------------------------------------------------------
# Bearbeitet werden:
#
#   Gosteli-Archiv
#   KB Trogen
#   Rorschach-Archiv
#   SWA-Privatarchive
#   ZHB Luzern
#   HAD-Tektonik
# --------------------------------------------------------------------
# history:
#   new 07.04.2015/bmt
#   added ZHB 30.04.2015/bmt
#   send log file per e-mail 17.02.2017

# -------------------------------
# Optionen
# -------------------------------
QUIET=0             # wenn 1: bleibe stumm
DO_REFRESH_DSV05=1  # wenn 1: aktualisiere dsv05.seq


# -------------------------------
# files & directories
# -------------------------------

DATE=`date +%Y%m%d`
NOW=`date`
LINE='------------------------------------------------'

DSV05_DIR=/opt/data/dsv05/
DSV05_SEQ=$DSV05_DIR/dsv05.seq
HOME=/opt/scripts/htb/
LOGDIR=/opt/scripts/htb/log
LOG=$LOGDIR/han_htb_$DATE.log
MAIL="aleph-ub@unibas.ch,lorenz.hofer@unibas.ch"

# -------------------------------
# Funktionen
# -------------------------------

say () {
    # Ausgabe auf Bildschirm (laesst sich unterdruecken mit QUIET=1)
    if [ "$QUIET" != "1" ]; then echo "$1"; fi
}

# -------------------------------
# Hauptprogramm
# -------------------------------

echo $LINE >> $LOG
echo 'Generiere HAN-Archive' >> $LOG
echo $LINE >> $LOG
echo "START: $NOW"  >> $LOG

cd $HOME

cd han_gosteli_archiv
./make-gosteli.sh >> $LOG 2>> $LOG
cd $HOME

cd han_kb_trogen
./make-trogen.sh >> $LOG 2>> $LOG
cd $HOME

cd han_rorschach_archiv
./make-rorschach.sh >> $LOG 2>> $LOG
cd $HOME

cd swa_privatarchive
./make-swapa.sh >> $LOG 2>> $LOG
cd $HOME

cd han_luzern_tektonik
./make-luzern.sh >> $LOG 2>> $LOG
cd $HOME

cd ub_tektonik
./make-tektonik.sh >> $LOG 2>> $LOG
cd $HOME

cd ub_nachlass
./make-ubnachlass.sh >> $LOG 2>> $LOG
cd $HOME

echo "END: $NOW"  >> $LOG

# Log-Datei nach jedem Lauf verschicken:
cat $LOG | mailx -a "From:aleph-ub@unibas.ch" -s "Logfile: HAN-Hierarchien erstellt ($DATE)" $MAIL

