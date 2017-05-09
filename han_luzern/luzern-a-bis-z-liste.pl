#!/usr/bin/perl

# luzern-az-liste.pl
# mache die A-Z Liste der Nachlaesse fuer die ZHB Luzern
#
# History
# 9.09.2010 / Andres von Arx

use strict;
use ava::datum;
use ava::sort::utf8;

my $infile  = 'tmp/toplevel.tmp';
my $outfile = 'output/han-zhb-luzern-nachlaesse-a-bis-z.html';

open(IN,"<$infile") or die("cannot read $infile: $!");
my @lines = <IN>;
close IN;

# -----------------------------------
# RUN 1: Koerperschaften
# -----------------------------------
my $Template = Template();
my $result = $Template->{head};
my $datum = ava::datum::datum;
$result =~ s/%%DATUM%%/$datum/;
$result .= $Template->{start_koerperschaft};
$result .= $Template->{start_tabelle};
$result .= formatiere_buchstabe('&nbsp;');
foreach ( @lines ) {
    chomp;
    my($sysno,$text,$details,$typ) = split /\|/;
    next if ( $typ ne 'k' );
    $result .= formatiere_eintrag($sysno,$text,$details);
}
$result .= $Template->{end_tabelle};

# -----------------------------------
# RUN 2: Personen
# -----------------------------------
$result .= $Template->{start_personen};
$result .= $Template->{start_tabelle};
my($previous_char);
foreach ( @lines ) {
    chomp;
    my($sysno,$text,$details,$typ) = split /\|/;
    next if ( $typ ne 'p' );
    my $current_char = substr(utf8sort_uc($text),0,1);
    if ( $current_char ne $previous_char ) {
        $previous_char = $current_char;
        $result .= formatiere_buchstabe($current_char);
    }
    $result .= formatiere_eintrag($sysno,$text,$details);
}
$result .= $Template->{end_tabelle};
$result .= $Template->{tail};

open(OUT,">$outfile") or die("cannot write $outfile: $!");
print OUT $result;
close OUT;

sub formatiere_buchstabe {
    my($buchstabe)=shift;
    local $_ = $Template->{buchstabe};
    s/%%BUCHSTABE%%/$buchstabe/g;
    $_;
}
sub formatiere_eintrag {
    my($sysno,$text,$details)=@_;
    local $_ = ( $details eq '#ja#' ) ? $Template->{eintrag_mit_details} : $Template->{eintrag};
    s/%%SYSNO%%/$sysno/g;
    s/%%TEXT%%/$text/g;
    $_;
}

# -----------------------------------------------------------------
# Template für die HTML-Schnipsel
# -----------------------------------------------------------------
sub Template {
    my $Template = {
        'head' => <<'EOD',
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>UB Basel HAN: Nachlässe ZHB Luzern A-Z</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<script type="text/javascript" src="aleph_session_1.js"></script>
<script type="text/javascript" src="aleph_session_2.js"></script>
<script type="text/javascript" src="aleph_han.js"></script>
<style type="text/css">
body,td { font-family:sans-serif; font-size:90%; }
a { color: black; }
a:hover { background-color:#CCCC99; }
</style>
</head>
<body>
UB Basel HAN
<h1>Nachlässe ZHB Luzern A-Z</h1>
<div style="width:600px">
<p><b>Anleitung</b><br>
Diese Seite enthält HTML-Schnipsel zum Einfügen in die Seite
<a href="http://www.zhbluzern.ch/navi.cfm?st1=200&amp;st2=75&amp;st3=200&amp;st4=25&amp;w=16829&amp;status=4">
Sondersammlung Nachlässe A-Z</a> der ZHB Luzern. Die zu kopierenden Abschnitte
sind im Quelltext markiert. - Dazu dient diese Seite auch als Spickzettel dafür,
welche Javascript-Dateien eingebunden werden sollten, damit die Links zur HAN-Datenbank
in Basel funktionieren.</p>
<p><b>Achtung</b>: die Links auf die Seiten mit einem elekronischen Nachlassverzeichnis
müssen noch von Hand eingetragen werden. Das lässt sich natürlich auch automatisieren,
z.B. mit einer Konkordanztabelle zwischen HAN-Systemnummer und der Luzerner Webseite.
Aber wie heisst's so schön in den Programmierhandbüchern: <i>"I&nbsp; shall leave this
as an exercise for the reader."</i></p>

<p>Stand der Daten: %%DATUM%%</p>
</div>
<hr>
<br>
<div style="margin-left:1cm">
EOD
        'start_koerperschaft' =>  qq|<big><big>[Körperschaften]</big></big><br>\n|,
        'start_personen' => qq|<br><br><big><big>[Personen]</big></big><br>\n|,
        'start_tabelle' => <<'EOD',
    <table width="100%" border="0" summary="">
      <colgroup>
        <col width="20">
        <col width="10">
        <col width="93%">
      </colgroup>

<!-- ****************** ab hier einfügen ********************* -->
EOD
        'buchstabe' => <<'EOD',
      <tr>
        <td>%%BUCHSTABE%%</td>
        <td>&nbsp;</td>
        <td>&nbsp;</td>
      </tr>
EOD
        'eintrag' => <<'EOD',
      <tr>
        <td>&nbsp;</td>
        <td>&nbsp;</td>
        <td><a href="javascript:hanopen('%%SYSNO%%')">%%TEXT%%</a></td>
      </tr>
EOD
        'eintrag_mit_details' => <<'EOD',
      <tr>
        <td>&nbsp;</td>
        <td>&nbsp;</td>
        <td><a href="javascript:alert('***_Bitte_Link_einfuegen_***')">%%TEXT%%</a> (elektronisches Nachlassverzeichnis)</td>
      </tr>
EOD
        'end_tabelle' => <<'EOD',
<!-- ****************** ende einfügen ********************* -->
    </table>
EOD
        'tail' => <<'EOD',
</div>
</body>
</html>
EOD
    }
}
