#!/usr/bin/python

# Author: Alex Babyrev
# Date: 3/2/2017
# This script takes one a zendesk json API
# Loops over the paginated results (100 per page maximum)
# Prints Zendesk users' names

import getpass
import requests
import pprint

# prompt user for Zendesk login
user = raw_input("\nEnter your ZenDesk\nUsername: ")
pw = getpass.getpass("ZenDesk Password for " + user + ":")

list_names = open("Zendesk_users-plus-IDs.txt", 'a')

# Loop over each page and print to file only relevant user data from the detailed json data

index=1

while (index <=24):

    url = 'https://advancedigital.zendesk.com/api/v2/users.json?page='+str(index)
    response = requests.get(url, auth=(user, pw))

    if response.status_code != 200:
        print('Status:', response.status_code, 'Problem with the request. Exiting.')
        exit()

    data = response.json()

    user_list = data['users']
    for usr in user_list:
        list_names.write(str(usr['name'])+":"+str(usr['email'])+":"+str(usr['id']))
        #print usr['name'], usr['email']
        list_names.write("\n")

    index+=1

list_names.close()
