#!/usr/bin/perl

## This script pulls usernames from Gigya via API URL then quiries the username against MT database to get email address
## https://moderation.advance.net/admin/auth/user/?p=0 displays users with "Super Moderator" or "Community Manager"and "moderator" access too
## Users in group "Super Moderator" or "Community Manager" have PII access, those are the users this script queries from the API URL 

use lib qw (
    /var/www/cgi-bin/mte/lib
    /var/www/cgi-bin/mte/extlib
);

use lib '/var/www/cgi-bin/mte/plugins/AdvanceCommunity/extlib/';
use lib '/var/www/cgi-bin/mte/plugins/AdvanceCommunity/extlib/JSON/WebToken/Crypt/';
use JSON::WebToken;
use Date::Parse;
use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;
use MT;

$ENV{MT_HOME} = '/var/www/cgi-bin/mte/';

my $mt = MT->instance;

require MT::Author;

my $local_time = `date`;
my $unix_time = str2time($local_time);

my $secret = "QjrtZKN3A8zQFjzM4TuL2WEHqqB+QbMyMS2e8tNkjG0=";

my $jwt = JSON::WebToken->encode({
timestamp => $unix_time,
},$secret, 'HS256', {typ => 'JWT'}

);

### Get a list of users from Gigya ###
#$gigya_usernames=`curl -s https://maas-uat.advance.net/reports/pii_users/?key=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0aW1lc3RhbXAiOjI0MjU1MDkxNTZ9.ZH0DMv0RYygrbuLAPj65SycsbL7rEFUCTrDAIdOtN18 | cut -d',' -f 1`;

$gigya_usernames = `curl -s https://moderation.advance.net/reports/pii_users/?key=$jwt | cut -d',' -f 1 | sort`; 

my $temp = `curl -s https://moderation.advance.net/reports/pii_users/?key=$jwt|sed "s/\\r/\\n/g" | sed '/^\$/d'`;
my @temp_arr = split(/\n/, $temp);
@author_names = split(/\n/, $gigya_usernames);

$DB::single = 1;

### Get Gigya users info from MT ###
my @authors = MT::Author->load(
    { name => \@author_names, status => 1 },
    { fetchonly => [ 'nickname', 'name', 'email' ] }
);

my ( $id, $name, $nickname, $email, $email_domain );
foreach my $author ( @authors ) {
    $nickname = $author->nickname;
    $name = $author->name;
    $email = $author->email;
    $email_domain = ( split '@', $email )[1];
    my @match = grep (/$name/i, @temp_arr);
    push (@gigya_string, @match); 
    my $gigya_part = join('',@gigya_string);
    $nickname =~ s/,/ /g;
    print "$match[0],$nickname,$email,$email_domain\n";
    }

