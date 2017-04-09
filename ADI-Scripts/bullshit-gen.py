#!/usr/bin/python

from jira import JIRA
from termcolor import colored
import getpass
from jira.client import JIRA
from jira.exceptions import JIRAError

#username = raw_input(colored("Enter your JIRA username: ", 'green'))
username = "ababyrev@advancelocal.net"
print colored("\nEnter your JIRA password:", 'green')
pw = getpass.getpass()
server='https://jira.advance.net'

options = {
     'server': server
     }

try:
    jira = JIRA(options=options, basic_auth=(username, pw))

except JIRAError as e:
    if e.status_code == 401:
        print "Login to JIRA failed. Check your username and password"

with open('JIRAS.txt') as fp:
    for line in fp:
        issue = jira.issue(line.rstrip("\n\r"))
        with open ("Meeting-bullshit.txt","ab") as output:
            output.write("\n\n%s: %s\n\n%s %s. %s" % (issue.key, issue.fields.summary, issue.fields.status, issue.fields.issuetype.name, issue.fields.description))
