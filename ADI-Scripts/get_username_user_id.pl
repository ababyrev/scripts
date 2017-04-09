#!/usr/bin/perl

use DBI;
use Term::ANSIColor;

### Get commandline args ###

my ($string_array) = @ARGV;

### Connect to MT4 DB and get URL and site path ###
my $driver = "mysql";
my $database = "mt4";
my $port = '3306';
my $host = '275-mt-prod-rodb-01.host.advance.net';
my $dsn = "DBI:mysql:database=$database;host=$host;port=$port";
my $userid = "mt4ro";
my $password = "n0t40ng!";
my $dbh = DBI->connect($dsn, $userid, $password);

foreach (@ARGV) {

 my $sth = $dbh->prepare("SELECT author_nickname, author_email, author_name, author_id  FROM mt_author WHERE author_email=\"$_\" OR author_nickname LIKE \"\%$_%\" OR author_name LIKE \"\%$_%\"");
  $sth->execute() or die $DBI::errstr;

while ( ($author_nickname,$author_email,$author_name,$author_id) = $sth->fetchrow_array( ) )

{
         print "$author_nickname,$author_email,$author_name\n";
         print color("blue"), "https://blog.advance.net/cgi-bin/mte/mt.cgi?__mode=view&_type=author&id=$author_id\n\n", color("reset");
}
}
color("reset");
$dbh->disconnect;

