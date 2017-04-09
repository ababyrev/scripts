#! /usr/bin/perl -w

#Author: Alex Babyrev
#Date: 10/2015
#Purpose: Lock LDAP accounts

use strict;
use Getopt::Long;

my $master_host="275-sys-prod-ldapmaster-01.host.advance.net";

my $username;

GetOptions("username=s", \$username);

die "Usage: ./lock_ldap.pl --username=ldap_uid" if ! defined ($username );

my $dn=`ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" uid="$username" | grep dn: | cut -f2 -d ":" | sed "s/^ //"`;

my $checkIfLocked = `ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" uid="$username" \* nsAccountLock | grep -i "nsaccountlock:"`;

if ($checkIfLocked){ die "\n$username already has nsAccountLock attribute and it's: $checkIfLocked\n"};

if ($dn eq ""){die "username: $username not in LDAP\n";}

chomp(my $me = `/usr/bin/whoami`);

my $ldif_file = "$username.ldif";

chomp($dn);

open FILE, ">", "$ldif_file" or die $!;

my $full_ldif = "dn: $dn\nchangetype: modify\nadd: nsAccountLock\nnsAccountLock: true\n";

print FILE "$full_ldif\n";

close(FILE);

lock_ldap($me,$master_host,$username,$dn,$full_ldif,$ldif_file);

sub lock_ldap
 {

  open FILE, ">", "$ldif_file" or die $!;
  print FILE "$full_ldif";
  close(FILE);

  system("ldapmodify -x -H ldap://$master_host -D \"uid=$me,ou=People,dc=advance,dc=net\" -W -f $ldif_file");

  unlink "$ldif_file" or warn "Could not delete $ldif_file, please remove manually.\n";

  return;

 }

my $locked_user=`ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" uid="$username" \* dn nsAccountLock`;

print "$locked_user\n";
