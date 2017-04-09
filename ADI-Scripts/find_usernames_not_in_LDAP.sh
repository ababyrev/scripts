#!/bin/bash

while read line; do 

    member=`ldapsearch  -LLL -x -h 275-sys-prod-ldapmaster-01.host.advance.net -b "dc=advance,dc=net" "(uid=$line)" uid | grep dn:`

    #echo $member
    if [ -z "$member" ]
    then
    echo $line
    fi

done < $1
