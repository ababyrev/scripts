#!/usr/bin/python

# Author: Alex Babyrev
# Description: Compare two CSV files row by row and cell by cell and print matches

import csv
import sys
import pprint
import subprocess

# Function to convert a csv file to a list of dictionaries.  Takes in one variable called "variables_file"
# iterate over the rows and map values to a list of dictionaries containing key/value pairs
def csv_dict_list(variables_file):

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

# Pass CSV file as an option to this script, it will have users that you want to match in Active Directory CSV 
device_values = csv_dict_list(sys.argv[1])
#pprint.pprint(device_values)

# This is the file with all AD users from Austin that you need to search through
filename = "AD-Users.csv"

for item in device_values: # CSV with users you trying to match to AD
    with open(filename,"r+") as f: # CSV of all AD users
        for line in f:  # Name,Email 
            if (","+item["BAD-NAME"].lower()+"^" in line.lower() or ","+item["EMAIL"].lower()+"," in line.lower()):
                line = line.rstrip()
                print (line+","+item["UID"])
