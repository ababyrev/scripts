#! /usr/bin/perl -w


#Author: Alex Babyrev
#Date: 10/2015
#Purpose: Paste 3 lines of user info as an argument to this script and create a wiki account in LDAP plus add that user to proper PDLs plus email the login to the user


	use Term::ANSIColor;
	use POSIX qw( strftime );
	use Digest::SHA1 ("sha1");
	use MIME::Base64;

# Here is the ldap hostname that Sys Ops may change in the future and forget to tell us
my $master_host="275-sys-prod-ldapmaster-01.host.advance.net";

# This test will stop script from executing if ldapsearch does not return results
`ldapsearch -LLL -x -H ldap://$master_host -b "dc=advance,dc=net" uid=* -z 1` or die "Could not search ldap";

chomp($me = `/usr/bin/whoami`);

# User pastes 3 lines into their prompt
print "paste like this:\n Name: employee name here\n\n Email: employee email address\n\nPhone: phone#\n   Then press Enter followed by CTRL-D:\n";
my @input = <STDIN>;
my $input_string = join(":",@input);

$input_string =~ s/\n|\r//g;
$input_string =~ s/::/:/g;

my @delimited_array = split /:/,$input_string;

# The each one of the 3 lines that user pasted are delimieted by ':' so input exoecting 6 array elements 
if(scalar(@delimited_array) != 6){die "Missing information! Need, Name, Email, Phone in that order.\n";}

# Get only name, email, phone from array and assign to scalars
my $name = $delimited_array[1];
my $email = $delimited_array[3];
my $phone = $delimited_array[5];

# Do some basic character validation
if ($name !~ m/[a-zA-z]/){die "\nCheck name!\n";}
if ($email !~ m/.+@.+\..+/){die "\nCheck email address format!\n";}
if ($phone !~ m/[0-9]/){die "\nCheck phone number!\n";}

# Remove spaces from start and end of strings
$name =~ s/^\s+|\s+$|\n|\r//g;
$email =~ s/^\s+|\s+$|\n|\r//g;
$phone =~ s/^\s+|\s+$//g;

my @newarray = ("$name","$email","$phone");

foreach(@newarray){print color('cyan');print "\n$_\n";print color('reset');}

print color('yellow');print "Is this what you entered? Enter [Y]Yes or [N]No: ";print color('reset');

 chomp(my $correct = <STDIN>);
 unless($correct eq "Y" || $correct eq "y" || $correct eq "yes" || $correct eq "Yes" || $correct eq "YES"){die "Good bye!\n";}

# Get domain part from email address
$org = $email;
$org =~ s/.*@//;

foreach $i (@delimited_array){
 $i =~ s/.*://; 
 $i =~ s/^ | $//;

 my @full_name = split(" ",$name);
 my $full_name_size = $#full_name + 1;
  if ($full_name_size == 2){
    $fname=$full_name[0];
    $lname=$full_name[1];
    $mname="";
    $big_name = $fname." ".$lname;
} elsif($full_name_size == 3){
    $fname=$full_name[0];
    $mname=$full_name[1];
    $lname=$full_name[2];
    $big_name=$fname." ".$mname." ".$lname;
}else {die "\nFull name has to have 2 or 3 parts\n"};
}

$fname =~ s/\W*//g;
$lname =~ s/\W*//g;
$mname =~ s/\W*//g;

# Prepare password
$password = lc(substr($fname, 0, 1)).uc(substr($lname, 0, 1)).'!'.strftime("%m%d%Y", localtime);
my ($date, $salt, $hashedPasswd) = make_hash();


# Check if user exists based on first and last name plus email address
#my $cn_ldap = `ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" cn="$big_name" | grep -m1 cn: | cut -f2 -d ":" | sed "s/^ //"`;
my $mail_address = `ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" mail="$email" | grep -m1 mail: | cut -f2 -d ":" | sed "s/^ //"`;
my $dn=`ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" "(&(cn=$big_name)(mail=$email))" | grep dn: | cut -f2 -d ":" | sed "s/^ //"`;

chomp($dn);
chomp($mail_address);


# If user already in ldap then offer to reset password
print "DN: $dn\n";
if($dn =~ /[a-zA-Z]/){
 my $user_exists = `ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" "(&(cn=$big_name)(mail=$email))" | grep uid: | cut -f2 -d " "`;
 chomp($user_exists);
   print color('red');print "\n\n$big_name already has LDAP account with username $user_exists and email: $mail_address and organization: $org\n"; print color('reset');
        print color('green');print "\nReset LDAP password for $big_name? Press[y] to reset OR Press[n]to exit: "; print color('reset');
                chomp(my $answer = <STDIN>);
                        if($answer eq "y" || $answer eq "Y")
                                {

                                   @dn_uid=split(',',$dn);
                                   $uid=$dn_uid[0];
                                   $uid =~ s/uid=//;

                                        pw_reset($dn, $hashedPasswd, $me);
                                        $message=pw_reset_email($uid, $big_name, $password, $email);
                                        print "Email with wiki username $uid and password: $password was sent to: $message\n";
                                        exit;
                                }else
                                        {
                                                die "You can reset his LDAP password manually to $password \n"
                                        };
}


# Get PeopleSoft username - assuming it will be unique by deafult so no reason to check if already exists in LDAP

if($dn !~ /[a-zA-Z]/) {

#if($big_name =~ /[a-zA-Z]/){die "Matches existing name: $big_name - check if user already has LDAP account with another email\n";}
#if($mail_address =~ /[a-zA-Z]/){die "Matches existing email: $mail_address - check LDAP for user with same email\n";}

print "\nThis is a new user, enter PeopleSoft username: "; 
my $username = <STDIN>;
unless ($username =~ /^[a-z]+([0-9]+)?$/i) {die "Enter PeopleSoft username (username must be all letters or letters with number at the end)\n"};
my $temp = lc $username;
chomp($temp);
our $username = $temp;
}
print "You entered PeopleSoft username: $username\n";

#if($username){
# my $username_ldap = `ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" uid=$username | grep uid: | cut -f2 -d " "`;
# my $fullname_ldap = `ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" uid=$username | grep cn: | cut -f2 -d ":"`;
# my $existing_email = `ldapsearch -x -H ldap://$master_host  -b "dc=advance,dc=net" uid=$username | grep mail: | cut -f2 -d ":"`;
 
# chomp($fullname_ldap);
# chomp($username_ldap);
 
# if($username_ldap){
#   print color('red');print "\n\nUsername $username_ldap already exists and belongs to $fullname_ldap $existing_email $org\n";print color('reset');
#	die "Please use http://mailform.dev.advance.net/cgi-bin/ldif_gen.cgi\n";
#  }
#}

print "\nUsername: $username\nName: $big_name\nemail: $email\norg: $org\nphone: $phone\nToday's date: $date\n\n";

my $ldif="dn: uid=$username,ou=People,dc=advance,dc=net\nuid: $username\nuserPassword: $hashedPasswd\ncn: $big_name\ngivenName: $fname\nsn: $lname\nobjectClass: top\nobjectClass: person\nobjectClass: organizationalPerson\nobjectClass: inetorgperson\nmail: $email\no: $org\ntelephoneNumber: $phone\ndescription: Imported Account for Wiki - $date\n\ndn: cn=adv-confluence-users,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n";


	if($org eq "cleveland.com" || $org eq "advance-ohio.com"){
$pdl = "\n\ndn: cn=cleve-plaindealer,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=cleve-sunnews,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=cleve-staff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n";
}

	elsif($org eq "al.com"){
$pdl="\n\ndn: cn=bama-birminghamnews,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=bama-huntsvilletimes,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=bama-pressregister,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=bama-staff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=bama-mississippipress,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n";}

	elsif($org eq "nj.com" || $org eq "njadvancemedia.com" || $org eq "jjournal.com" || $org eq "pennjerseyacs.com" || $org eq "omj.com"){$pdl="\n\ndn: cn=njo-jerseyjournal,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=njo-sjnewsco,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=njo-staff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=njo-starledger,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=njo-timesoftrenton,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n";}
	
	elsif($org eq "mlive.com" || $org eq "acsmi.com"){
		$pdl="\n\ndn: cn=mlive-baycitytimes,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=mlive-flintjournal,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=mlive-grandrapidspress,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=mlive-jacksoncitizenpatriot,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=mlive-kalamazoogazette,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=mlive-muskegonchronicle,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=mlive-saginawnews,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=mlive-annarbor,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=mlive-staff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net";}

	elsif($org eq "lehighvalleylive.com"){
		$pdl="\n\ndn: cn=lvlive-expresstimes,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\n";}

	elsif($org eq "masslive.com"){
		$pdl="\n\ndn: cn=mass-republican,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\n";}
	
	elsif($org eq "nola.com"){
		$pdl="\n\ndn: cn=nola-timespic,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=nola-staff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\n";}


	elsif($org eq "oregonlive.com" || $org eq "oregonian.com"){
		$pdl="\n\ndn: cn=olive-allstaff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=olive-hillsboroargus,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=olive-oregonian,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\n";}


	elsif($org eq "pennlive.com"){
		$pdl="\n\ndn: cn=penn-staff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=penn-patriotnews,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\n";}

	elsif($org eq "silive.com"){
		$pdl="\n\ndn: cn=silive-staff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=silive-advance,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\n";}

	elsif($org eq "syracuse.com"){
		$pdl="\n\ndn: cn=syr-staff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\ndn: cn=syr-poststandard,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\n";}

	elsif($org eq "advance.net"){
		$pdl="\n\ndn: cn=adv-staff,ou=pdls,dc=advance,dc=net\nchangetype: modify\nadd: member\nmember: uid=$username,ou=People,dc=advance,dc=net\n\n";}

	else{die "$org is not mathcing PDLs defined in this script, contact ababyrev\@advance.net\n";}



$full_ldif = $ldif.$pdl;
$ldif_file = "$username.ldif";

open FILE, ">", "$ldif_file" or die $!;

print FILE "$full_ldif\n";

close(FILE);

print "(Your LDAP password) ";
#system("ldapadd -v -x -H ldap://$master_host -D \"uid=$me,ou=People,dc=advance,dc=net\" -W -f $ldif_file") == 0 or die "ldapadd failed!\n";
system("ldapadd -x -H ldap://$master_host -D \"uid=$me,ou=People,dc=advance,dc=net\" -W -f $ldif_file") == 0 or die "ldapadd failed!\n";

send_email($username, $email, $password);

print "\nNew wiki login email has been sent directly to $person\n";

unlink $ldif_file or warn "Could not delete $ldif_file, please remove manually.\n";


# Generates random password salt
sub make_salt
{
   my $length=32;
   $length = $_[0] if exists($_[0]);
   my @tab = ('.', '/', 0..9, 'A'..'Z', 'a'..'z');
   return join "",@tab[map {rand 64} (1..$length)];
}

sub make_hash
{
 my $date = strftime("%m/%d/%Y", localtime);
 my $salt = make_salt(4);
 my $hashedPasswd = "{SSHA}" . encode_base64(sha1($password . $salt) . $salt,'' );
 return ($date,$salt,$hashedPasswd);
}

sub pw_reset 
 {

  $pw_reset_ldif="dn: $dn\nchangetype: modify\nreplace: userPassword\nuserPassword: $hashedPasswd\n";

  open FILE, ">", "pw_reset.ldif" or die $!;
  print FILE "$pw_reset_ldif";
  close(FILE);

print "(Your LDAP password) ";

  system("ldapmodify -x -H ldap://$master_host -D \"uid=$me,ou=People,dc=advance,dc=net\" -W -f pw_reset.ldif");

  #unlink "pw_reset.ldif" or warn "Could not delete pw_reset.ldif, please remove manually.\n";

  return;
  
 }

#-----------------------------------  THIS PART BELOW EMAILS USER WIKI LOGIN ------------------------------------------------------

sub send_email 

{

$mailprog = '/usr/lib/sendmail';

$subject="Your New Advance Digital Wiki Account";

$person="$email";

open(MAIL,"|$mailprog -t");

print MAIL "To: $person\n";
print MAIL "From: Alex Babyrev <ababyrev\@advance.net>\n";
print MAIL "Subject: $subject\n\n";

### This is the body of the message you are sending out ####
print MAIL "
Hello $big_name,

Greetings from Advance Digital. Please find here your new login and password to access Advance Digital Newspaper Starting Point site as well as any other appropriate section on our wiki (our internal intranet site). Your username and password are below:

Username: $username
Password: $password

You can log into the wiki at: https://wiki.advance.net

These are your individual credentials; we ask that you do not share them with anyone. Please discontinue using any other login you may have had in the past.

If you need assistance with your wiki account only, you may reach us at https://support.advance.net/ or by calling 877-577-6012. For all other inquiries, please use the Newspaper Starting Point.

Best Regards,


Alex Babyrev
Advance Support
201.459.2851
";

return $person;

}



sub pw_reset_email

{

$mailprog = '/usr/lib/sendmail';

$subject="Your Wiki Account password has been reset";

$person="$email";

open(MAIL,"|$mailprog -t");

print MAIL "To: $person\n";
print MAIL "From: Alex Babyrev <ababyrev\@advance.net>\n";
print MAIL "Subject: $subject\n\n";

### This is the body of the message you are sending out ####
print MAIL "
Hello $big_name,

Greetings from Advance Digital. Please find here your new password to access Advance Digital Newspaper Starting Point site as well as any other appropriate section on our wiki (our internal intranet site). Your username and password are below:

Username: $uid
Password: $password

You can log into the wiki at: https://wiki.advance.net

These are your individual credentials; we ask that you do not share them with anyone. Please discontinue using any other login you may have had in the past.

If you need assistance with your .wiki. account only, you may reach us at https://support.advance.net/ or by calling 877-577-6012. For all other inquiries, please use the Newspaper Starting Point.

Best Regards,


Alex Babyrev
Advance Support
201.459.2851
";

return $person;

}
