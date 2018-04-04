#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'uninitialized';

# Data::Dumper for debugging
use Data::Dumper;

# XML::Writer to write output file
use XML::Writer;
use IO::File;

# Unicode-support in the Perl script and for output
use utf8;
binmode STDOUT, ":utf8";

# Min Max functions
use List::Util qw(min max);

# Catmandu-Module for importin Aleph sequential
use Catmandu::Importer::MARC::ALEPHSEQ;
use Catmandu::Fix::marc_map as => 'marc_map';

# Check arguments
die "Argumente: $0 DSV05.seq SWA-Subject heading, Output Dokument\n"
  unless @ARGV == 3;

# Define hashes with information exported out of the .seq file (hash key = system number)
my (
    %f245, 
    %f490w,
    %f490i,
);

# Sysnum-Array contains all the system numbers of all MARC records
my @sysnum;

# Catmandu importer to read each MARC record and export the information needed to generate the xml file
my $importer = Catmandu::Importer::MARC::ALEPHSEQ->new( file => $ARGV[0] );
$importer->each(
    sub {
        my $data       = $_[0];
        my $sysnum     = $data->{'_id'};
        $data          = marc_map( $data, '245a', 'f245a' );
        $data          = marc_map( $data, '245b', 'f245b', '-join', ', ' );
        $data          = marc_map( $data, '245c', 'f245c', '-join', ', ' );
        $data          = marc_map( $data, '490w', 'f490w' );
        $data          = marc_map( $data, '490i', 'f490i' );
        $data          = marc_map( $data, '773w', 'f773w' );
        $data          = marc_map( $data, '852[ , ]a', 'f852a' );
        $data          = marc_map( $data, '909f', 'f909f' );

        # Generate title-field from subfields
        my $f245 = $data->{f245a};
        #isbd( $f245, $data->{f245b}, " : " );
        #isbd( $f245, $data->{f245c}, " / " );

        # Edit linking field: Make sure there are leading zeros. If field 773 is present, overwrite field 490 with the contents of field 773
        my $f490w  = sprintf( "%-9.9d", $data->{f490w} );
        my $f773w = sprintf( "%-9.9d", $data->{f773w} );
        $f490w = $f773w unless $f490w;

        my $f490i = $data->{f490i};

        # Select which records have to be exported (all SWA records withou 909-code hide this)
        if ( !($data->{f909f} =~ /hide_this/) ||  $data->{f852a} =~ /Basel UB Wirtschaft - SWA/ ) {
            # If a record has to be exported, we read in its field (already manipulated) into hashes (key = sysnum)
            push( @sysnum, $sysnum );
            $f245{$sysnum} = ($f245);
            $f490w{$sysnum} = $f490w;
            $f490i{$sysnum} = $f490i;
        }
    }
);

#Read in the file containing the swa subject headings and the fond-level records

open(my $in, '<:encoding(UTF-8)', $ARGV[1]) or die "Could not open file '$ARGV[1]' $!";

open(my $out, '>:encoding(UTF-8)', $ARGV[2]) or die "Could not open file '$ARGV[2]' $!";

my @keys = sort { $f490i{$a} <=> $f490i{$b} } keys %f490i;
 
while (my $row = <$in>) {
    chomp $row;
    print $out "$row\n";

    $row =~ /^( *)/;
    my $level = $1;

    if ($row =~ /> ([0-9]{9})$/) {
        my $topnum = $1;
        foreach ( @keys ) {
            my $sysnum = $_;
            if ( $f490w{$sysnum} == $topnum) {
                my $newlevel = $level;
                $newlevel .= ' ';
                print $out $newlevel .  $f245{$sysnum} . ' > ' . $sysnum . "\n";
                addchildren($sysnum,$newlevel);
            }
        }
    } 
}

close $out;
close $in;

# Sub to find and convert childern records
sub addchildren {
    # Check for each record (=keys f490) if there is a record with the system number of the present record ($_[0]). If found, print the line for this record.
    for my $child ( @keys ) {
        if ( $f490w{$child} == $_[0] ) {
            my $newlevel = $_[1];
            $newlevel .= ' ';
            print $out $newlevel .  $f245{$child} . ' > ' . $child . "\n";
            addchildren($child,$newlevel);
        }
    }
}

# Gives back the maximum length of the arrays given as arguments
sub maxarray {
    my $max;
    foreach my $i ( 0 .. ( @_ - 1 ) ) {
        $max = scalar @{ $_[$i] } if scalar @{ $_[$i] } > $max;
    }
    return $max;
}

# Checks if the variable is both defined and not an empty string
sub hasvalue {
    my $i = 1 if defined $_[0] && $_[0] ne "";
    return $i;
}

# Links together MARC subfields including interpunction
sub isbd {
    if ( hasvalue( $_[1] ) ) {
        $_[0] = $_[0] . $_[2] . $_[1] . $_[3];
    }
}   

exit;
