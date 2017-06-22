#!/bb/bin/bbpy

import subprocess
import os, sys, re
from datetime import datetime
import time

F1STAGE = 'f1stage'
#HOST = 'nylxdev6'
SCRIPT = 'fetchbigs.sh'
FORMAT = '%Y:%m:%d:%H:%M'
DT_FORMAT = '%Y:%m:%d'
HH_MM_FRMT = '%H:%M'


# !!!!!!  rewrite this as a dictionary of with hostname as keys and fetchbigs.done as value 

# Get list of host names that will be getting new software files
MACH_LIST = subprocess.Popen(['/bb/bin/owin',F1STAGE,'cat /bb/bin/machinelist'], stdout=subprocess.PIPE)
READ_HOSTNAMES = MACH_LIST.stdout.read()

# Loop through each host in a machine list /bb/bin/machinelist
for HOST in  READ_HOSTNAMES.splitlines():

    # Get output from psef fetchbigs.sh
    PSEF_PROC = subprocess.Popen(['/bb/bin/owin',HOST,'/bb/bin/psef',SCRIPT],stdout=subprocess.PIPE)
    READ_PSEF = PSEF_PROC.stdout.read()

    # Count number of hosts that will be getting software
    TOTAL_MACHINES = subprocess.Popen(['/bb/bin/owin',F1STAGE,'wc -l < /bb/bin/machinelist'], stdout=subprocess.PIPE)
    READ_TOTAL = TOTAL_MACHINES.stdout.read()

    # Split the output from psef fetchbigs.sh into CSV
    CSV = re.sub("\s+", ",",READ_PSEF.strip()).split(",")
 
    # Check if CSV[12] has a start time value 
    try:
        S_TIME = CSV[12] # CSV[12] should contain the start time for fetchbigs.sh
    except IndexError:
        S_TIME = 'null' # If CSV[12] is not set then set S_TIME to 'null'
    
    if S_TIME == 'null': # If CSV[12] does not contain the start time then script is not running
         
        FTETCH_FILE = subprocess.Popen(["/bb/bin/owin",HOST,"ls -l","/bb/bin/fetchbigs.done"],stdout=subprocess.PIPE)
        IS_FETCH_FILE_DONE = FTETCH_FILE.stdout.read()
        print IS_FETCH_FILE_DONE
        continue

    # Compare STIME of fetchbigs.sh and current time and find difference
    REMOTE_YYMMDD = subprocess.Popen(['/bb/bin/owin',HOST,'date +'+DT_FORMAT], stdout=subprocess.PIPE)
    RMT_DT = REMOTE_YYMMDD.stdout.read()
    # Variable with remote machine date and time in YYYY:MM:DD:HH:MM format
    RMT_DT = RMT_DT.rstrip()

    PROC_START_DATE_TIME = str(RMT_DT)+":"+str(CSV[12])

    # Get current remote host date and time: YYYY:MM:DD;HH:MM format
    REMOTE_YYYYMMDDHHMM = subprocess.Popen(['/bb/bin/owin',HOST,'date +'+FORMAT], stdout=subprocess.PIPE)
    RMT_YYYMMDDHHMM = REMOTE_YYYYMMDDHHMM.stdout.read()
    # Variable with remote machine date and time in YYYY:MM:DD:HH:MM format
    RMT_CLEAN = RMT_YYYMMDDHHMM.rstrip()

    print "PROC_START_DATE_TIME: %s\nRMT_CLEAN: %s" %(PROC_START_DATE_TIME,RMT_CLEAN)

    # Diffeence between STIME and current time
    STIME = datetime.strptime(PROC_START_DATE_TIME, FORMAT)
    RC_TIME = datetime.strptime(RMT_CLEAN, FORMAT)
    DIFF = RC_TIME - STIME

    print SCRIPT+" has been running since: "+str(STIME)+" for: %s" %(DIFF)
