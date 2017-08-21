#/bin/bash

# Author: Alex Babyrev
# Date: 08/2017
# Purpose: If waitfile for .trap is running longer than 10 minute, touch .trap file

# Function that converts HH:MM to seconds
t2s()
{
  local T=$1;shift
  echo $((10#${T:0:2} * 3600 + 10#${T:3:2} * 60 + 10#${T:6:2})) 
}


# Store output from psef waitfile in an array and parse out STIME and .trap file path and name
mapfile -t PSEF < <(psef waitfile | grep ".trap$" | awk -v OFS=',' '{print $8,$9,$10}')

for i in "${PSEF[@]}" # Start loop and iterate over each line in PSEF array

do

# Each iteration, we are subsctracting process start time from current time in 'HH:MM' format.
  STIME=$(echo $i | awk -F "," '{print $1}') # Parse out the STIME in HH:MM
  
  TRAP_FILE=$(echo $i | awk -F "," '{print $3}') # Parse out the .trap path and filename 
  
  TIME_NOW=`date +"%H:%M"` # Get current HH:MM

  diff_time=$(( $(t2s $TIME_NOW) - $(t2s $STIME) )) # Get number of seconds process has been running.

  DURATION=$(expr $diff_time / 60) # Divide seconds by 60 to get minutes.

# If waitfile has been waiting on .trap for more than 10 minutes, touch .trap
  if [[ $DURATION > 10 ]];
    then
      echo "$i - took $DURATION minutes which is longer than 10 minutes - running: touch $TRAP_FILE to continue"
  fi      
  
done # End loop
