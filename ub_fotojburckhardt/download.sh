#!/bin/bash

# Stand 18.03.2013/abi

# INFO: Vor dem Start dieses Skriptes muss folgendes ausgefuehrt werden:

# getestet fuer ALEPH 20

# => Aleph File: Selektion und  Download (ACHTUNG: Datenbank auf DSV05 wechseln!)

# 1.1 Selektion
# GUI dsv05: Services / Datensaetze suchen / Datensaetze mit CCL suchen (ret_03)
# - CCL: sin=NL 13 : 39?
# - Output: fotobur [$alephe_scratch]

# 1.2 fotobur-marc
# GUI dsv05: Services / Datensaetze suchen / Datensaetze drucken (print_03)
# - Input: fotobur
# - Output: fotobur-marc [dsv05/scratch]
# - Feld 1: ALL
# - Format: ALEPH Sequential
# Achtung: ADM-Nutzung = aus!, sonst im dsv51/scratch

# nun kann untenstehendes Skript ausgefuehrt werden:

if [ -f tmp/fotobur-marc ]
	then echo 'tmp/fotobur-marc existiert bereits - will nicht ueberschreiben!'
	exit
fi

echo '* download'

wget http://aleph.unibas.ch/dirlist/u/dsv05/scratch/fotobur-marc -O tmp/fotobur-marc

if [ $? -ne 0 ]
	then echo 'Download fehlgeschlagen: Vielleicht zuerst noch die ALEPH-Abfragen machen?'
	exit
fi

echo '* fix marc file'
../htb/htb_alephseq_to_marcxml tmp/fotobur-marc tmp/fotobur.xml
