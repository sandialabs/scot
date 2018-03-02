#!/usr/bin/env perl
use strict;
use warnings;
use v5.18;

use Net::SSH::Perl;
use Net::SFTP;
use IO::Prompt;

say "=================================================";
say "= $0 ";
say "= retrieve SCOT database backups from ";
say "= remote SCOT server via SSH and restore ";
say "= them locally ";
say "=";
say "= SCOTDB source = hostname of remove SCOT server ";
say "= username      = that can read /opt/scotbackups";
say "= password      = for username";
say "=================================================";

my $host    = prompt("Enter SCOTDB Source > ");
my $user    = prompt("Enter Username      > ");
my $pass    = prompt("Enter Password      > ", -e => '*');
my $downdir = prompt("Download to Dir     > ");
my $srcdir  = "/opt/scotbackup";

if ( $host eq "localhost" ) {
    say "implement me";
    die "do it now";
}

my $ssh     = Net::SSH::Perl->new($host);
   $ssh->login($user,$pass);

my ($stdout, $stderr, $exit ) = $ssh->cmd('cd '.$srcdir.'; ls -lh *tgz');

printf("%3s   %14s   %s   %s\n","---","-"x14, "-"x25, "-"x4);
printf("%3s   %14s   %s   %s\n","id","Date","Filename","Size");
printf("%3s   %14s   %s   %s\n","---","-"x14, "-"x25, "-"x4);
my $id = 0;
my %filemap = ();
foreach my $line (split(/\n/,$stdout)) {
    $id++;
    my @pieces  = split(/\s+/,$line);
    my $size    = $pieces[4];
    my $date    = join(' ',$pieces[5] , $pieces[6] , $pieces[7]);
    my $file    = $pieces[8];
    $filemap{$id} = $file;
    printf("%3s   %14s   %s   %s\n",$id, $date, $file,$size);
}
printf("%3s   %14s   %s\n","---","-"x14, "-"x25);
my $did = prompt("SELECT ID to Download > ");

my $file = $filemap{$did};

say "Attempting to SCP $host:$srcdir/$file to $downdir";
my $remote = "$srcdir/$file";
my $local  = "$downdir/$file";

my $sftp = Net::SFTP->new($host, user => $user, password => $pass);
   $sftp->get($remote, $local, sub {
        my ($sftp, $data, $offset, $size) = @_;
        print "Read $offset / $size bytes\r";
    });
print "\n";

system("cd $downdir; tar xzvf $file");

my $dbname = prompt("Enter Database Name to restore to > ", -d => "scot-prod" );
#my $cmd = "/usr/bin/mongorestore --db $dbname --dir $downdir/opt/scotbackup/mongo/scot-prod --drop";
my $cmd = "mongorestore  -d $dbname --dir $downdir/opt/scotbackup/mongo/scot-prod --host=mongodb:27017 --drop";


say "Executing $cmd...";
system($cmd);

say "Restoring Cached images...";
system("cp -r $downdir/opt/scotbackup/cached_images/ /opt/scot/public/");

say "Now fixing IDs in mongodb";
system("perl fix_last_id.pl");





