#!/home/ababyrev/anaconda3/pkgs/python-3.5.2-0/bin/python

import csv
import sys
import pprint
import subprocess
 
# Function to convert a csv file to a list of dictionaries.  Takes in one variable called "variables_file"
 
def csv_dict_list(variables_file):
     
    # Open variable-based csv, iterate over the rows and map values to a list of dictionaries containing key/value pairs
 
    reader = csv.DictReader(open(variables_file, 'rt'))
    dict_list = []
    for line in reader:
        dict_list.append(line)
    return dict_list

"""
Calls the csv_dict_list function, passing the named csv
Convert CSV to a list of dictionaries and return that list
NOTE: This CSV has to have a list in this format: 
LDAP-UID,LDAP-CN,LDAP-Email
ababyrev,Alex Babyrev,ababyrev@advance.net
"""

# Prints the results nice and pretty
#pprint.pprint(device_values)

# Open CSV of LDAP users 
device_values = csv_dict_list(sys.argv[1])

#pprint.pprint(device_values)

# This is the file with all AD users from Austin that you need to search through
filename = "AD-uid-coma-adname-email"

for item in device_values:
    with open(filename,"r+") as f:
        for line in f:  # AD-UID,LDAP-CN 
            if (","+item["LDAP-UID"].lower() in line.lower() or item["LDAP-CN"].lower()+"," in line.lower() or ","+item["LDAP-MAIL"].lower()+"," in line.lower()):
                line = line.rstrip()
                print (line+","+item["LDAP-UID"].lower())

