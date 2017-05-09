#!/usr/bin/perl

# Input:
# - Hierarchie-XML
# - marcNNNNNNNNN.xml (eine MARC XML Datei pro Datensatz)
#
# Output:
# - Hierachie XML, angereichert mit Daten
#
# History:
# - 3.08.2010/andres.vonarx@unibas.ch
# - 29.12.2014/basil.marti@unibas.ch

use strict;
use FindBin;
use lib "$FindBin::Bin/../htb";
#use Data::Dumper; $Data::Dumper::Sortkeys=1; $Data::Dumper::Indent=1;
use Getopt::Long;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21' );
use MARC::Record;

sub usage {
    print<<EOD;
usage: $0 [options]

options
--infile     input: Hierarchie-XML
--outfile    output: Hierarchie-XML mit angereicherten <data>
--marcdir    Verzeichnist mit marcNNNN.xml Dateien
EOD
    exit;
}
my($infile,$outfile,$marcdir);
GetOptions (
    "infile=s"      => \$infile,
    "outfile=s"     => \$outfile,
    "marcdir=s"     => \$marcdir,
    ) or usage;
( $infile ) or usage;
( $marcdir ) or usage;
$outfile ||= '-';

binmode(STDOUT,'utf8');
binmode(STDERR,'utf8');

open(IN,"<$infile") or die("cannot read $infile: $!");
binmode(IN,'utf8');
open(OUT,">$outfile") or die("cannot write $outfile: $!");
binmode(OUT,'utf8');
while ( <IN> ) {
    if ( m|^( +<rec level="." recno=")(\d+)| ) {
        my $reclevel=$1;
        my $recno=$2;
        my $numbering=$3;
        my $nachlass;
        if ( m|(<nachlass>.*</nachlass>)| ) {
            $nachlass=$1;
        }

        my $marcfile=$marcdir .qq|/marc$recno.xml|;
        my $str;
        open(MARC,"<$marcfile") or die("cannot read $marcfile: $!");
        binmode(MARC,'utf8');
        { local $/; $str=<MARC>; }
        close MARC;
        my $rec=MARC::Record->new_from_xml($str,'utf8','USMARC');

        # -- Autor
        my $autor='';
        my $ma=$rec->subfield('100', "a");
        my $aa=$rec->subfield('700', "a");
        my $co=$rec->subfield('710', "a");
        my $ma2=$rec->subfield('100', "b");
        my $aa2=$rec->subfield('700', "b");
        my $co2=$rec->subfield('710', "b");

        if ( defined ($ma) ) {
        	if (not defined($ma2) ) {
            		$autor='<autor>' .safexml($ma) .'</autor>';
        	}
		elsif  ( defined($ma2) ) {
			$autor='<autor>' .safexml($ma) . ' ' . safexml($ma2) . '</autor>';
		}
	} elsif (defined( $aa) ) {
		if (not defined( $aa2) ) {
            		$autor='<autor>' .safexml($aa) .'</autor>';
        	}
		elsif  ( defined ($aa2) ) {
			$autor='<autor>' .safexml($aa) . ' ' . safexml($aa2) . '</autor>';
		}
	} elsif (defined ( $co) ) {
                $autor='<autor>' .safexml($co) .'</autor>';
	};

        # -- Titel
        my $titel='';
        my $f=$rec->field('240') || $rec->field('245');
        if ( $f ) {
            $titel='<titel>' .safexml($f->subfield('a')) .'</titel>';
        }

        # -- Anzeigeform Zaehlung (490 $v)
        my $zaehlung='';
        $f=$rec->field('490');
        if ( $f ) {
            $zaehlung='<zaehlung>' .safexml($f->subfield('v')) .'</zaehlung>';
        }

        $_=qq|$reclevel$recno"><data>$nachlass$autor$titel$zaehlung</data>\n|;
    }
    print OUT $_;
}
close IN;
close OUT;

sub safexml {
    local $_=shift;
    s|&|&amp;|g;
    s|<|&lt;|g;
    s|>|&gt;|g;
    s|"|&quot;|g;
    s|'|&apos;|g;
    $_;
}
