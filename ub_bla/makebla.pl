# rev. 24.01.2008/ava

use strict;
use Data::Dumper;
use HTML::Entities;

use ava::alephx;
use ava::datum;
use ava::sort::isolatin1;
use ava::template;

# -- input (ISO-8859-1) --
my $AutMarcFile = 'blaaut.marc';    # print-01 mit Feldnummern, normalisiert
my $AutCardFile = 'blaaut.txt';     # SysNo, Tab, ISBD
my $LitCardFile = 'blalit.txt';     # ISBD, Tab, SysNo, Tab, Signaturen
my $IniFile     = 'bla.ini';        # Steuerdatei für das uralt-Perl-Modul ava::alephx.pm
my $AddOnDir    = '/intranet/edv/public/bla';       # Verzeichnis mit Zusatztexten

# -- output (ISO-8859-1) --
my $OutDir      = 'output';
my $Autoren_AZ  = 'autoren.htm';
my $Anonyma     = 'anthologien.htm';
my $Bibliog     = 'bibliog.htm';
my $ErrorFile   = 'error.txt';

# -- templates
my $Template_Autor  = 'template-bla-autor.htm';
my $Template_AZ     = 'template-bla-autoren-a-z.htm';
my $Template_Anonyma= 'template-bla-anthologien.htm';
my $Template_Bibliog= 'template-bla-bibliog.htm';

# -- aleph links
my $Aleph_Sysno_Template = 'http://aleph.unibas.ch/F?func=find-b&amp;find_code=SYS&amp;request=';
my $Aleph_Aut_Template   = 'http://aleph.unibas.ch/F?func=find-b&amp;find_code=AUT&amp;request=';

my $Datum = ava::datum::datum2;
(my $Jahr = ava::datum::dateshort) =~ s/-.*$//;
my $SEP = "\t";
my $txt='';
my $Sysnos;

print "Analysiere...\n";
open(ERR,">$ErrorFile") or die "cannot write $ErrorFile: $!";


# Installationspruefung:
( -d $OutDir ) or die("Das Verzeichnis $OutDir muss vorhanden sein!");

# -----------------------------------------------
# mache eine Liste der Autoren und Anthologien (mit Sysno)
# -----------------------------------------------
my ($Autoren,$Displayform_Autor);
my $Anthologien = [];
my ($TotalAutoren,$TotalAutorenwerke,$TotalAnonyma);
my $alephx = define_input($IniFile);
set_input_file($alephx,$AutMarcFile);
start_import($alephx);
while ( my $rec = get_bibrec($alephx) ) {

    if ( $rec->{aut2} ) {
        push(@{$rec->{autor}},@{$rec->{aut2}});
    } elsif ( $rec->{aut1} ) {
        push(@{$rec->{autor}},@{$rec->{aut1}});
    }
    delete $rec->{aut1};
    delete $rec->{aut2};

    unless ( $rec->{titel} ) {
        print ERR $rec->{sysno}[0], " ignoriert (kein Titel, vermutlich alte x-Aufnahme)\n";
        next;
    }
    unless ( $rec->{signatur} ) {
        if ( $rec->{stufe}[0] eq 'a' ) {
            # Analyticum ohne Signatur. Wird stillschweigend ignoriert
            # print ERR $rec->{sysno}[0], " ignoriert (Analyticum, keine Signatur)\n";
        } else {
            print ERR $rec->{sysno}[0], " FEHLER: keine BLA Signatur\n";
        }
        next;
    }
    if ( $rec->{autor}[0] ) {
        add_author($rec);
    }
    else {
        add_anthologie($rec);
    }
}

# -----------------------------------------------
# mache eine Liste der Systemnummern mit Kurzkatalogisat
# -----------------------------------------------
open(F,"<$AutCardFile") or die "cannot read $AutCardFile: $!";
while ( <F> ) {
    chomp;
    my($a,$b)=split /\t/o;
    $b =~ s/##/ /g;
    $Sysnos->{$a} = trim($b);
}

# -----------------------------------------------
# formatiere Autorenseiten
# -----------------------------------------------
foreach my $sortform_autor ( sort keys %$Autoren ) {
    my $autor = $Displayform_Autor->{$sortform_autor};
    my $autor_file = $OutDir .'/' . aut_filename($autor);
    my $aufnahmen = format_aut_aufnahmen( $Autoren->{$sortform_autor} );
    my $aleph_aut_link = format_aut_link($autor);
    my($addon, $addon_is_text, $addon_is_table);
    my $AddOnFile = addon_filename($autor);
    if ( -f $AddOnFile ) {
        $addon = read_add_on($AddOnFile);
    }
    if ( $addon ) {
        if ( $addon =~ /<table/i ) {
            $addon_is_table = $addon;
            $addon_is_text = ' ';
        }
        else {
            $addon_is_text = $addon;
            $addon_is_table=' ';
        }
    }
    $txt = apply_template({
        file  => $Template_Autor,
        text  => {
            NAME        => $autor,
            AUFNAHMEN   => $aufnahmen,
            DATUM       => $Datum,
            ALEPH_AUT   => $aleph_aut_link,
            ADD_ON      => $addon,
            ADD_ON_TEXT => $addon_is_text,
            ADD_ON_TAB  => $addon_is_table,
        }});
    open(F, ">$autor_file") || die "kann $autor_file nicht schreiben: $!";
    print F $txt;
    close F;
}

# -----------------------------------------------
# Indexseite Autoren
# -----------------------------------------------

# zaehle Autoren pro Buchstaben
my %az;
my @Sort_Autoren;
foreach my $sortform_autor ( sort keys %$Autoren ) {
    ($az{substr($sortform_autor,0,1)})++;
    push(@Sort_Autoren, $Displayform_Autor->{$sortform_autor});
    $TotalAutoren++;
}

# formatiere Indexseite
$txt='';
my $Spalten = 3;
foreach my $letter ( sort keys %az ) {
    $txt .= print_index_letter_bar($letter);
    my $cnt = $az{$letter};
    my $max = int(($cnt+$Spalten-1)/$Spalten);
    my($spalte1, $spalte2, $spalte3);
    for ( my $i = 0 ; $i < $max ; $i++ ) {
        $spalte1 .= ( $cnt-- > 0) ? link_to_authorfile( shift @Sort_Autoren ) : '';
    }
    for ( my $i = 0 ; $i < $max ; $i++ ) {
        $spalte2 .= ( $cnt-- > 0) ? link_to_authorfile( shift @Sort_Autoren ) : '';
    }
    for ( my $i = 0 ; $i < $max ; $i++ ) {
        $spalte3 .= ( $cnt-- > 0) ? link_to_authorfile( shift @Sort_Autoren ) : '';
    }
    $spalte1 =~ s/<br>\n$//;
    $spalte2 =~ s/<br>\n$//;
    $spalte3 =~ s/<br>\n$//;
    $spalte1 .= '&nbsp;';
    $spalte2 .= '&nbsp;';
    $spalte3 .= '&nbsp;';
    $txt .=<<EOD;
<table summary="" width="100%" border="0" cellpadding="0" cellspacing="0">
<tr valign=top>
<td width="33%">$spalte1</td>
<td width="33%">$spalte2</td>
<td width="33%">$spalte3</td>
</tr>
</table>
EOD
    }
$txt = apply_template({
        file  => $Template_AZ,
        text  => {
            LISTE   => $txt,
            DATUM   => $Datum,
            JAHR    => $Jahr,
        }});
open(F, ">$OutDir/$Autoren_AZ") || die "kann $OutDir/Autoren_AZ nicht schreiben: $!";
print F $txt;
print "$OutDir/$Autoren_AZ\n";
close F;

# -----------------------------------------------
# Anthologien
# -----------------------------------------------
$txt='';
foreach my $titel ( sort @$Anthologien ) {
    $TotalAnonyma++;
    my(undef,$sysno,$sig) = split(/\t/,$titel);
    my $isbd = $Sysnos->{$sysno};
    my $link = $Aleph_Sysno_Template . $sysno;
    $txt .= qq|<p>$isbd<br><em><a href="$link" target="dsv">Signatur: $sig</a></em></p>\n|;
}
$txt = apply_template({
        file  => $Template_Anonyma,
        text  => {
            LISTE   => $txt,
            DATUM   => $Datum,
            JAHR    => $Jahr,
        }});
open(F, ">$OutDir/$Anonyma") || die "kann $OutDir/$Anonyma nicht schreiben: $!";
print "$OutDir/$Anonyma\n";
print F $txt;
close F;

# -----------------------------------------------
# Bibliographie
# -----------------------------------------------

open(F,"<$LitCardFile") or die "cannot read $LitCardFile: $!";
my @lines = <F>;
close F;
$txt='';
@lines = sort isolatin1sort @lines;
while ( @lines ) {
    my $line = shift @lines;
    chomp $line;
    my($isbd,$sysno,$sig)=split(/\t/,$line);
    $isbd =~ s/\s*##\s*/<br>/g;
	$sysno =~ s/\D//g;
    my @sig = split(/\s*##\s*/,$sig);
    while ( @sig ) {
        $sig = shift @sig;
        next unless ( $sig =~ /^Standort: Basel UB/ );
        next unless ( $sig =~ s/^.*Signatur: BLA/Signatur: BLA/ );
        last;
    }
    if ( $sig ) {
        my $link = $Aleph_Sysno_Template .$sysno;
        $txt .= qq|<p>$isbd<br><a href="$link" target="dsv">$sig</a></p>\n|;
    }
    else {
        print ERR $sysno, " FEHLER: keine BLA Signatur (code blalit)\n";
    }
}
$txt = apply_template({
        file  => $Template_Bibliog,
        text  => {
            LISTE   => $txt,
            DATUM   => $Datum,
            JAHR    => $Jahr,
        }});
open(F, ">$OutDir/$Bibliog") || die "kann $OutDir/$Bibliog nicht schreiben: $!";
print "$OutDir/$Bibliog\n";
print F $txt;
close F;

# -----------------------------------------------
# Statistik
# -----------------------------------------------
print<<EOD;

Total Autoren:          $TotalAutoren
Total AutorenWerke:     $TotalAutorenwerke
Total Sammelschriften:  $TotalAnonyma

EOD

# -----------------------------------------------
# Fehler
# -----------------------------------------------
close ERR;
if ( (stat($ErrorFile))[7] ) {
    print "ACHTUNG: Es sind Fehler aufgetreten.\n",
        "Deteils siehe $ErrorFile\n";
}
else {
    unlink $ErrorFile;
}

print "\nFertig.\n";
# -----------------------------------------------

sub link_to_authorfile {
    my $aut = shift;
    my $file = aut_filename($aut);
    qq|<a href="$file">$aut</a><br>\n|;
}

sub print_index_letter_bar {
    # schreibt eine link bar mit buchstaben a-z
    my $current_letter = uc(shift);
    my $start= 65;  #  'A'
    my $stop = 90;  #  'Z'
    my $buchstabe ='A';
    my($i,$ret);

    $ret = "<a name=\"$current_letter\"></A>\n";
    $ret .= "<div><hr size=1>\n";
    for ( $i = $start ; $i <= $stop ; $i++ ) {
        $buchstabe = sprintf("%c", $i);
        if ( $buchstabe ne $current_letter ) {
            $ret .= sprintf( "<a href=\"#%c\">%c</a> &nbsp; ", $i, $i );
        }
        else {
            $ret .= " <strong>$current_letter</strong> &nbsp; ";
        }
    }
    $ret .= "\n<hr size=1></div>\n";
}

sub format_aut_aufnahmen {
    my $aref = shift;
    @$aref = sort @$aref;
    my $ret;
    while ( @$aref ) {
        local $_ = shift @$aref;
        $TotalAutorenwerke++;
        my(undef,$sysno,$sig) = split /\t/;
        my $isbd = $Sysnos->{$sysno};
        my $link = $Aleph_Sysno_Template . $sysno;
        $ret .= qq|<p>$isbd<br><em><a href="$link" target="dsv">Signatur: $sig</a></em></p>\n|;
    }
    $ret;
}

sub format_aut_link {
    local $_=shift;
    $_ = sortform($_);
    s|[^ a-z,]||g;
    s| \s+| |g;
    $_ = trim($_);
    s| |%20|g;
    $Aleph_Aut_Template . $_;
}

sub read_add_on {
    my $file = shift;
    local($/,$_,*F);
    open(F,"<$file") or die "cannot read $file: $!";
    $_=<F>;
    close F;
    s|^.*<body>\s*||isg;
    s|</body.*$||isg;
    s|<h1>.*</h1>\s*||is;
    s|<h2>|<p><strong>|ig;
    s|</h2>|</strong></p>|ig;
    # Tabelle
    s|<table[^>]*>|<table border="0" cellpadding="3" cellspacing="0">|i;
    s|<tr[^>]*>|<tr valign="top">|i;
    s|<td|<td class="info"|ig;
    # Abstandsspalte einfuegen
    s|</td>|</td><td class="info" width="20">&nbsp;</td>|i;
    $_;
}

sub sortform {
    local $_ = shift;
    $_ = ava::sort::isolatin1::lc($_);
    s/[^\- a-z]//g;
    s/\s+/ /g;
    $_ = trim($_);
}

sub fileform {
    local $_ = shift;
    $_ = sortform($_);
    s/[^a-z]/_/g;
    s/__/_/g;
    s/_$//;
    $_;
}

sub aut_filename {
    'bla_' .substr(fileform($_[0]),0,15) .'.htm';
}

sub addon_filename {
    $AddOnDir .'/' .fileform($_[0]) .'.htm';
}

sub add_author {
    # $Autoren->{sortform} = [ titelliste, ... ]
    # $Displayform_Autor{sortform} = displayform
    my $rec=shift;

    my $tit = $rec->{titel}[0];
    $tit = sortform($tit);
    $tit =~ s/\s+/ /g;
    $tit = trim($tit);
    my $tmp = $tit .$SEP .$rec->{sysno}[0] .$SEP . join($SEP, @{$rec->{signatur}});

    foreach my $aut ( @{$rec->{autor}} ) {
        my $displayform = trim($aut);
        my $sortform = sortform($displayform);
        push(@{$Autoren->{$sortform}},$tmp);
        $Displayform_Autor->{$sortform} = $displayform;
    }
}

sub add_anthologie {
    my $rec=shift;
    my $tit = $rec->{titel}[0];
    $tit = sortform($tit);
    $tit =~ s/\s+/ /g;
    $tit = trim($tit);
    my $tmp = $tit .$SEP .$rec->{sysno}[0] .$SEP . join($SEP, @{$rec->{signatur}});
    push(@$Anthologien, $tmp);
}

sub trim {
    local $_=shift;
    s/^\s+//;
    s/\s+$//;
    $_;
}
