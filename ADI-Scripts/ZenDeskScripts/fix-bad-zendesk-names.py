#!/usr/bin/python

# Written by Alex babyrev 03/06/2017
# Autoamtically corrects zendesk user first and last name field in Zendesk by utilizing Zendesk JSON API

import csv
import json
import requests
import getpass
import  sys

# Authenticate into Zendesk as Agent
user = raw_input("\nEnter your ZenDesk\nUsername: ")
pwd = getpass.getpass("ZenDesk Password for " + user + ":")


# Function that makes list of dictionaries out of CSV you passed to this script as an option
def csv_dict_list(variables_file):

    reader = csv.DictReader(open(variables_file, 'rt'))
    dict_list = []
    for line in reader:
        dict_list.append(line)
    return dict_list

# Save list of dictionaries in variable
device_values = csv_dict_list(sys.argv[1])

log_file = open("log-of-JSON-API-URLs-of-updated-users","a")

# Loop through each row in CSV and update name field for each user in Zendesk based on their UID
for item in device_values:
    # User to update
    uid = str(item["UID"])
    full_name = str(item['GOOD-NAME'])

    # Package the data in a dictionary matching the expected JSON
    data = {"user": {"name": full_name}}

    # Encode the data to create a JSON payload
    payload = json.dumps(data)

    # Set the request parameters
    url = 'https://advancedigital.zendesk.com/api/v2/users/' + uid + '.json'
    headers = {"content-type": "application/json"}

    # Do the HTTP put request
    response = requests.put(url, data=payload, auth=(user, pwd), headers=headers)

    # Check for HTTP codes other than 200
    if response.status_code != 200:
        print('Status:', response.status_code, 'User id: '+uid+' Not updated')
        exit()

    # Report success
    log_file.write(str(url)+'\n')

log_file.close()
