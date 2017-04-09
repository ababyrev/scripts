#!/usr/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

if [ ! -f errors.sh ]; then
	printf "Script not found!\n"
	exit 1
fi

# Run to get the errors
mapfile -t lines < <(bash errors.sh|grep ERROR)

printf "\n${red}${#lines[@]}${reset} Errors found:\n\n"

printf '%s\n' "${red}${lines[@]}${reset}"

err1_txt="ERROR1: Something is wrong code 1232"
err2_txt="ERROR2: Something is very wrong code 321"
err3_txt="ERROR3: Disaster 666"


for i in "${lines[@]}"
do

  if [ "$i" == "$err1_txt" ]
    then
      printf "Fixing $i\n"
    fi

  if [ "$i" == "$err2_txt" ]
    then
      printf "\nFixing $i\n"
    fi

done

