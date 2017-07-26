#!/opt/bb/bin/bbpy

import os
import bas
import subprocess
from subprocess import check_output
import sys 
import getpass

while True:
	USER = getpass.getuser()
	UUID = int(subprocess.check_output(["/opt/quest/bin/vastool","attrs","-q",USER,"employeeID"]))

	prqssrvcService=bas.lookup("prqssrvc",1,79).tcpClient(userIdent=bas.UserIdent.factory(uuid=UUID))

	try:
	    PRQS = input('Please enter PRQS number: ')
	except NameError:
	    print 'I see you have entered a non-valid PRQS ED, please recheck your request'
	    exit()

	RESPONSE = prqssrvcService.PrqsEDGetRequest(PRQS)


	file =  RESPONSE.PrqsEDResponse.ED[0]

	lines = RESPONSE.PrqsEDResponse.ED[1]

	clusterTags = RESPONSE.PrqsEDResponse.ED[2]

	type = RESPONSE.PrqsEDResponse.ED[3]  
	if type == 3:
	    print 'Type = Remove'

	else:
	    if type == 2:
		print 'Type = Update.  I am not ready for updates yet! Exiting..'
		exit() 

	    else:
		if type == 1:
		    print 'Type = Add'

		else:
		    print 'Not an Add, Remove, or Update'
		    exit()

	linelist = []
	for x in lines:
	   linelist.append(x)

	if any("Please" in s for s in linelist):
	    linelist.pop(0)
	if any("append" in s for s in linelist):
	    linelist.pop(0)
	if any("following" in s for s in linelist):
	    linelist.pop(0)
	if any("add" in s for s in linelist):
	    linelist.pop(0)
	if any("Add" in s for s in linelist):
	    linelist.pop(0)
	if any("remove" in s for s in linelist):
	    linelist.pop(0)

	final_line = '\n'.join(linelist)

	def command(x, lines, file):
	    process = subprocess.Popen(['/bb/bin/owin', x, 'grep "', final_line, '"', file], stdout=subprocess.PIPE)
	    output = process.communicate()[0]
	    return


	clusterList = []
	clusterExclude = []
	tagRequire = []; tagBool = False
	machineListFinal = []
	for x in clusterTags:
		if x[0] == '-':
			clusterExclude.append(x[1:])
		elif x[0] == '^':
			tagRequire.append(x)
			tagBool = True
		else:
			clusterList.append(x) 

	print "including", clusterList
	print "requiring tag", tagRequire
	print "excluding", clusterExclude

	notfound =[]

	def findmachines(file):
	    for(index,cluster) in enumerate(clusterList):
		for line in open('/bb/bin/bbcpu.alias'):
		    if cluster == list(line.upper().split(" ")):
			print "changing", clusterList[index], "to", line.split(" ")[1]
			clusterList[index] = line.split(" ")[1]

	    clusterFoundDict={}
	    for cluster in clusterList:
		clusterFoundDict[cluster] = False
	    for line in open(file):
		skipBool=False
		for cluster in clusterList:
		    if cluster in list(line.upper().split(" ")):
			clusterFoundDict[cluster] = True
			for word in line.upper().split(" "):
			    if word in clusterExclude:
				 skipBool = True
			if skipBool:
			    pass
			else:
			    if tagBool:
				 for required in tagRequire:
				     if required[1:] in list(line.upper().split(" ")):
					 pass
				     else:
					 skipBool = True
			if skipBool:
			    pass
			else:
			    machineListFinal.append(line.split(" ")[0])

	    missingBool=True
	    for cluster in clusterList:
		if clusterFoundDict[cluster]:
		    pass
		else:
		    notfound.append(cluster)
		    missingBool=False
	    return missingBool


	if findmachines('/bb/bin/bbcpu.lst'):
	    print "findmachines on bbcpu.lst completed"
	else:
	    print notfound, "what was not found"
	    clusterList=notfound
	    findmachines('/bb/bin/bbcpu.alias')



	print machineListFinal
	print "total of ", len(machineListFinal), " machines"

	checkmachlist = []



	##Check string on machines"
	print "Strings are: ", final_line, "\n"
	for x in machineListFinal:
	    for line in final_line.split("\n"):
		osCommand='/bb/bin/owin '; osCommand+=x; osCommand+=" '"; osCommand+='grep -n "'; osCommand+=line; osCommand+='" '; osCommand+=file; osCommand+="' 2>/dev/null"
		#process = subprocess.Popen(['/bb/bin/owin', x, " '", ' grep "', line, '"', file, "'"], stdout=subprocess.PIPE)
		try:
			process = subprocess.check_output(osCommand, shell=True) 
		except:
			process = ""
		if type == 1:
		    if process == "":
			checkmachlist.append('found error in machine: '  + '\033[94m' + x + '\033[0m' + ' ' + line + '\033[91m' + ' NOT ADDED!!!\n' + '\033[0m')             


		if type == 3:
		    if process != "":
			checkmachlist.append('found error in machine: ' + '\033[94m'  + x + '\033[0m' + ' ' + line + '\033[91m' + ' NOT REMOVED!!!\n' + '\033[0m')
	 

		#output = process.communicate()[0]
		print x
		print "Checking: ", line , " in ", file
		print process
		print "---------------------------------------------------------------------"
		

	final_checkmachlist = '\n'.join(checkmachlist)

	if not checkmachlist:
	    output = subprocess.check_output(['banner', 'LOOKS'])
	    next_output = subprocess.check_output(['banner', 'GOOD']) 
	    print '\033[92m' + output 
	    print '\033[92m' + next_output
	    print '\033[0m'

	else:
	    print "Check the following machines: ", "\n" , final_checkmachlist
	    output = subprocess.check_output(['banner', 'PLEASE'])
	    next_output = subprocess.check_output(['banner', 'CHECK'])
	    print '\033[91m' + output
	    print '\033[91m' + next_output
	    print '\033[0m'
 
        print 'YOU CAN CONTROL + C OUT OF THIS SCRIPT NOW IF YOU WISH\n'
