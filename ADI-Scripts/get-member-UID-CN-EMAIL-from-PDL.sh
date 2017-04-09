#!/bin/bash


# This script takes list of PDLs as option to $1
# It will search PDL and return each member Uid,CN,Email 


while read PDL; do

pdl_members=$(ldapsearch  -LLL -x -h ldap-vip.advance.ly -b "dc=advance,dc=net" "(cn=$PDL)" member | grep "member: " | sed "s/member: //g")

while read member; do

uid_var=$(echo $member | awk -F"," '{print $1}')

ou_var=$(echo $member | awk -F"," '{print $2","$3","$4}')

username_cn_email=`ldapsearch  -LLL -x -h ldap-vip.advance.ly -b "$ou_var" "$uid_var" dn cn mail | grep -i "dn:\|cn:\|mail: [a-zA-Z0-9_\-\.]\+@[a-zA-Z0-9_\-]\+" | sed "/email.advance.net/d"`

username=$(grep "dn: " <<< "$username_cn_email" | awk -F"," '{print $1}' | awk -F"=" '{print $2}')
cn=$(grep "cn: " <<< "$username_cn_email" | sed "s/cn: //g")
email=$(grep "mail: " <<< "$username_cn_email" | sed "s/mail: //g")


if [ "$username" ] && [ "$cn" ] && [ "$email" ]; then
    echo $username,$cn,$email

elif [ ! "$email" ]; then
echo "Missing Email: "$username,$cn,$email
fi



done <<< "$pdl_members"

done < $1



<<comment
while read line; do

echo $line

members=`ldapsearch  -LLL -x -h ldap-vip.advance.ly -b "dc=advance,dc=net" "(cn=$line)" member|awk -F"," '{print $1}'|awk -F"=" '{print $2}'`

while read user;do
echo $members | grep -i -o "\b$user\b"
done < $2

done < $1
comment
