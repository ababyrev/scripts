#!/usr/bin/bash

#Author: Alex Babyrev
#Date: 04/2017
#Purpose: Automate error fixing process


#for colorizing error messages
 red=`tput setaf 1`
 green=`tput setaf 2`
 reset=`tput sgr0`

#Path to script that finds ERRORS
 ERROR_FINDER="errors.sh"

#Check if the script exists, exit if script is missing
 if [ ! -f "$ERROR_FINDER" ]; then
	printf "$ERROR_FINDER script not found!\n"
	exit 1
 fi

#Run errors.sh to get output and grep for ERROR lines
 mapfile -t lines < <(bash errors.sh|grep ERROR)

#Prints number of errors
 printf "\n${red}${#lines[@]}${reset} Errors found:\n\n"


#Print all ERRORS as an array
 printf '%s\n' "${red}${lines[@]}${reset}"

#Declare variables with ERROR text we're trying to match
 err1_txt="ERROR1: Something is wrong code 1232"
 err2_txt="ERROR2: Something is very wrong code 321"
 err3_txt="ERROR3: Disaster 666"


#Loop over every ERROR and if match then do something
 for i in "${lines[@]}"

  do

   if [ "$i" == "$err1_txt" ]
    then
      printf "\nFixing $i\n"
    fi

   if [ "$i" == "$err2_txt" ]
    then
      printf "\nFixing $i\n"
    fi

   if [ "$i" == "$err3_txt" ]
    then
      printf "\nFixing $i\n"
    fi

 done

