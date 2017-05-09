use strict;

# kopiere noch-nicht-existierende Bilddateien auf den Host
# 2.12.2005/ava, rev. 19.02.2012/ava

my $HOST = shift @ARGV;
if ( $HOST ne 'ub-webqm' && $HOST ne 'ub-webvm' ) {
    die "usage: $0 <ub-webqm|ub-webvm>\n";
}

my $source_dir = '/intranet/edv/public/bla/pic';
my $target_dir = '/export/www/htdocs/spez/bla/pic';

my %host_files  = map{$_=>1} split(/\n/, `ssh webmaster\@$HOST 'ls -1 $target_dir'`);
my @local_files = split(/\n/, `ls -1 $source_dir`);
my %local_files = map{$_=>1} @local_files;

foreach my $file ( @local_files ) {
    unless ( $host_files{$file} ) {
        system "scp $source_dir/$file webmaster\@$HOST:$target_dir";
    }
}

my $cmd='';
foreach my $file ( keys %host_files ) {
    unless ( $local_files{$file} ) {
        $cmd .= "ssh webmaster\@$HOST 'rm $target_dir/$file'\n";
        print $cmd, "\n";
    }
}
if ( $cmd ) {
    print "\n--- Zu loeschende Dateien (bitte manuell nachholen)\n$cmd\n";
}


