#!/usr/bin/perl

# Written by: Alex Babyrev
# Date: 07/2015
# Reason: Automate blog alias creation 


######### Need to add a check to search all files for existing alias:
######### my $find = `find /home/ababyrev/ssf_configs/impact_aliases/ -type f -name \"*\" | xargs grep -H "letters"`;


use DBI;

my $home = $ENV{"HOME"};

### Get commandline args ###

my ($string_array) = @ARGV;
my $regex = "^([0-9]+ )*[0-9]+\$";

if ($string_array !~ $regex) {
   print "\nUsage: $0 blog_id or $0 blog_d blog_id blog_id etc.\n";
    exit;
}

print "Enter JIRA number like this: ALIAS-#\n";
my $JIRA = <STDIN>;
chomp($JIRA);

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

$count = $dbh->selectrow_array("select count(*) entry_id from mt_entry where entry_blog_id=$_", undef, @params);


if  ($count == 0){die "Blog ID: $_ needs to have at least 1 local entry (not reblogged/multiblogged entry)\n";}
else{print "Blog ID: $_ has $count entry\n"};

 my $sth = $dbh->prepare("SELECT blog_site_url, blog_site_path FROM mt_blog WHERE blog_id=$_");
  $sth->execute() or die $DBI::errstr;

while ( ($blog_site_url,$blog_site_path) = $sth->fetchrow_array( ) )  

{
         print "$blog_site_url\n$blog_site_path\n";


@affils = qw(adv njo penn lvlive syr mass mlive nola bama silive olive gulflive ohss nyup mardi cleve);
$site_url = $blog_site_url;
$site_root = $blog_site_path;

foreach (@affils) {

 if ($site_root =~ m/$_/){

   $affil_match = $_;

  }
}

### Check for basic issues with site root and url format ###
if ($site_url !~ /^http/){die "site URL should start with 'http'\n";}
#if ($site_root !~ /\/var\/www\/mte\/IMPACT\/$affil_match\//){die "Site root should start like this format: /var/www/mte/IMPACT/affil/\n";}
if ($site_url !~ /.*\/$/){die "missing trailing slash in site URL or URL ends in .index.ssf\n";}
if ($site_root !~ /^\/.*\/$/){die "missing first or trailing slash in site root\n";}

$site_domain = $blog_site_url;

$site_domain =~ /((^http:\/\/|^www.).+.com|.*.net)/;

$site_url =~ s/index.ssf.*//i;
$site_url =~ s/http:\/\/.*.com\/|http:\/\/.*.net\///;

# Check if main index exists on the filesystem because bamboo plan breaks if it does not exist
unless( -e "$site_root/index.html"){die "\nExiting script because: $site_root/\index.html does not exist\nPublish Main Index template first from: https://blog.advance.net/cgi-bin/mte/mt.cgi?__mode=list&_type=template&blog_id=$_\n";}

$site_root =~ s/\/var\/www\/mte\//\/mnt\/mtdocs\//;

#Check 00_original_aliases.txt file for existing alias

open( INPUTFILE, "$home/ssf_configs/impact_aliases/prod/$affil_match/00_original_aliases.txt" ) or warn "$home/ssf_configs/impact_aliases/prod/$affil_match/00_original_aliases.txt not found, continuing script...";

my @original_aliases = <INPUTFILE>;

close(INPUTFILE);

print "$affil_match\_impact_$site_url\n";

foreach my $line (@original_aliases) {

if ($line =~ /$affil_match\_impact_$site_url/) {

	die "The alias already exists: $line\n";
  }

}

###### Check all ALIAS or any file for existing alias ########
my $find = `find $home/ssf_configs/impact_aliases/ -type f -name \"*\" | xargs grep -H "$affil_match\_impact_$site_url"`;

if ($find){print "$find\n"; die "\nAlias exists!\n";}


#unless( -e "/var/www/mte/IMPACT/$affil_match/$site_url/index.html"){die "\nExiting script because: /var/www/mte/IMPACT/$affil_match/$site_url\index.html does not exist\nPublish Main Index template first from: https://blog.advance.net/cgi-bin/mte/mt.cgi?__mode=list&_type=template&blog_id=$_\n";}


$file=$ARGV[0];
chomp($file);

# Check if alias already exists by curling the river URL
my $curl=`curl -IsL '$1/$affil_match\_impact_$site_url/index_river.html' | grep '^HTTP' | grep -o '[0-9]\\{3\\}'`;

if ($curl == 200){die "The blog alias already exists\n";}


### Create the 99_ files ####
open TEST_STAGE, ">", "$home/ssf_configs/tests/stage/$affil_match/200/99_$JIRA" or die $!;
open TEST_PROD, ">", "$home/ssf_configs/tests/prod/$affil_match/200/99_$JIRA" or die $!;
open ALIAS_STAGE, ">", "$home/ssf_configs/impact_aliases/stage/$affil_match/99_$JIRA" or die $!;
open ALIAS_PROD, ">", "$home/ssf_configs/impact_aliases/prod/$affil_match/99_$JIRA" or die $!;

print TEST_STAGE "/$affil_match\_impact_$site_url\n";
print TEST_PROD "/$affil_match\_impact_$site_url\n";
print ALIAS_STAGE "Alias /$affil_match\_impact_$site_url $site_root\n";
print ALIAS_PROD "Alias /$affil_match\_impact_$site_url $site_root\n";


close TEST_STAGE;
close TEST_PROD;
close ALIAS_STAGE;
close ALIAS_PROD;

my $git_dir = "$home/ssf_configs/";
my $git_add = "git add $home/ssf_configs/tests/stage/$affil_match/200/99_$JIRA $home/ssf_configs/tests/prod/$affil_match/200/99_$JIRA $home/ssf_configs/impact_aliases/stage/$affil_match/99_$JIRA $home/ssf_configs/impact_aliases/prod/$affil_match/99_$JIRA";
my $git_commit = "git commit -m \"$affil_match alias updated for stage and prod see jira $JIRA\"";

chdir($git_dir);

system ('git pull');
system ($git_add);
system ($git_commit);
system ('git push');

print "Here is your blog Alias: $affil_match\_impact_$site_url\n";

print "$home/ssf_configs/tests/stage/$affil_match/200/99_$JIRA\n";
print "$home/ssf_configs/tests/prod/$affil_match/200/99_$JIRA\n";
print "$home/ssf_configs/impact_aliases/stage/$affil_match/99_$JIRA\n";
print "$home/ssf_configs/impact_aliases/prod/$affil_match/99_$JIRA\n";
print "\nhttps://bamboo.advance.net/browse/SYS-SC/\n";
}

warn "Problem in retrieving results", $sth->errstr( ), "\n"
        if $sth->err( );
}

$dbh->disconnect;
 
