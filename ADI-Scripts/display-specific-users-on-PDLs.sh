#!/bin/bash

# This script takes 2 options, $1 = list of PDLs and $2 = list of users
# It will print PDL name followed by only users that are on the list passed to $2

while read line; do

echo $line

members=`ldapsearch  -LLL -x -h ldap-vip.advance.ly -b "dc=advance,dc=net" "(cn=$line)" member|awk -F"," '{print $1}'|awk -F"=" '{print $2}'`

while read user;do
#echo $members | grep -i -o "\b$user\b" 
ldap_user=$(echo $user | awk -F"," '{print $2}') 
ad_user=$(echo $user | awk -F"," '{print $1}')

match=$(grep -i -o "\b$ldap_user\b" <<< "$members")

if [ "$match" ]; then
echo $ad_user","$match
fi
done < $2
    
done < $1
