#!/usr/bin/perl

# Author: Alex Babyrev
# Date: 5/2012
# Purpose: checking LDAP for duplicate uidNumbers

use Sys::Hostname;

my $thishost = hostname;

# This ldapsearch returns all uidNumber attributes in LDAP, it cleans up the output to only list the number itself and saves it in array
my @dupes=(`ldapsearch -LLL -x -H ldap://275-sys-prod-ldapmaster-01.host.advance.net -b "ou=People,dc=advance,dc=net" "uidNumber=*" uidNumber | grep "uidNumber: "| sed 's/uidNumber: //' | uniq -d | sed 's/\$/,/'|tr '\012' ' '`);

foreach $i (@dupes){print "$i";}

# only do anything if there are duplicates
if(@dupes){

# declare array and then push duplicate DN entries into it
my @dupe_dn;

foreach (@dupe_dn)

{

chomp($_);

# Search dn that duplicate uidNumbers belong to
my $dn = `ldapsearch -LLL -x -H ldap://275-sys-prod-ldapmaster-01.host.advance.net -b "ou=People,dc=advance,dc=net" uidNumber=$_ dn uidNumber createTimestamp creatorsName title o nsAccountLock` or die "Could not search ldap";

push (@dupe_dn, $dn);

}


######## use MAIL handle to email users ###########

$mailprog = '/usr/lib/sendmail';

$subject="LDAP users with duplicate uidNumber";

open(MAIL,"|$mailprog -t") or die "failed to open MAIL pointer in /home/support/pdl_audit/uidNumber_dupe_audit.pl script on $thishost";

print MAIL "To: ababyrev\@advance.net\n";
print MAIL "From: Cron on $thishost";
print MAIL "Subject: $subject\n\n";

print MAIL "===============================

@dupe_dn

===============================";

close (MAIL);
}
