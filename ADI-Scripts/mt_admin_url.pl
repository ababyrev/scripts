#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Getopt::Long;
use Term::ANSIColor;

my ($string_array) = @ARGV;


my $URL;

GetOptions("url=s", \$URL);

die "Usage: $0 --url=story URL" if ! defined ($URL );

chomp($URL);

$URL =~ s/\/\d\d\/(.*?)\.html//;

my $base_name = $1;

### Connect to MT4 DB and get URL and site path ###
my $driver = "mysql";
my $database = "mt4";
my $port = '3306';
my $host = '275-mt-prod-rodb-01.host.advance.net';
my $dsn = "DBI:mysql:database=$database;host=$host;port=$port";
my $userid = "mt4ro";
my $password = "n0t40ng!";
my $dbh = DBI->connect($dsn, $userid, $password);


my $sth = $dbh->prepare("select entry_id,entry_blog_id from mt_entry where entry_basename = \"$base_name\"");
  $sth->execute() or die $DBI::errstr;

while ( (my $entry_id, my $entry_blog_id) = $sth->fetchrow_array( ) )

{
         print color("blue"), "https://blog.advance.net/cgi-bin/mte/mt.cgi?__mode=view&_type=entry&id=$entry_id&blog_id=$entry_blog_id\n\n", color("reset");
}

$dbh->disconnect;

