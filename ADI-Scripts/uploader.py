#!/Users/ababyrev/env/bin/python
#!/Users/ababyrev/anaconda/bin/python
"""
Name: Alex Babyrev
First draft: 9/2016
Reason: Automated file uploader that uses Valence tool
Useage: ./uploader.py list_of_files_directories.txt endpoints.txt
where - you pass first option a file that contains a list of files and/or directories
you want to upload followed by second option which is a file that contains a list of endpoints.txt. The script
will make a system call to a program called 'valence' that you shold have installed on the server where you are running this script.
"""
from termcolor import colored
from sys import  argv
import os.path
import os, subprocess, re, urllib, time
import sys



# Return the /some_directory/file.ext from the list of files that need to be uploaded
def get_end_path(fullpath):
    print (fullpath)
    if not (os.path.isfile(fullpath)):
        return "Doesn't exist, skipping: "+fullpath+"\n"
    else:
         return fullpath

# subporcess call to valence to upload or update files into AWS S3 bucket

def valence_upload(file_path,URI,end_pnt):
    if not file_path.endswith((".ssf", ".bak", ".back", ".test")):
        try:
            print colored("1st upload attempt: "+file_path+"\n",'cyan')
            print subprocess.check_output(['valence', 'upload', file_path, 'META.json'])

        except:
            print colored("File already exists - updating existing file "+file_path+"\n",'blue')
            try:
                print colored("1st update attempt: "+subprocess.check_output(['valence', 'update', file_path, 'META.json']),'blue')
            except:
                  try:
                      print colored("Trying again... 2nd update attempt: "+subprocess.check_output(['valence', 'update', file_path, 'META.json']),'hot_pink_1a')
                  except:
                      return

        s3_bucket = end_pnt.replace("www", "https://s3.amazonaws.com/static")
        s3_url = str(s3_bucket)+str(URI)
        print s3_url+"\n"
        s3_url = s3_url.rstrip()

        with open ("temp_s3_uploaded.log","a+") as upload_log:
            upload_log.write(s3_url+"\n")
    else:
        print colored("...but because extension is (\".ssf\", \".bak\", \".back\", \".test\") it will not be uploaded\n",'yellow')
        with open ("temp_s3_rejected.log","a+") as rejects_log:
            rejects_log.write(file_path+"\n")


# This function is to recursively go through a directory and send filepath and endpoint to upload function
def upload_directory_contents(directory_path,endpoint):
     for dirName, subdirList, fileList in os.walk(directory_path):
         for fname in fileList:
             full_file_path=os.path.join(dirName, fname)
             full_file_path = full_file_path.rstrip()

             if os.path.isfile(full_file_path):
                 print colored(full_file_path+" is legitimate file\n",'green')
                 end_file = "/"+get_end_path(full_file_path)
                 end_pnt = endpoint.rstrip()
                 with open("META.json","w") as META:
                     META.write(
                     """
                     {
                     "endpoint": "%s%s",
                     "application": "MT",
                     "user": "ababyrev",
                     "tier": "prod",
                     "ttl": 3600,
                     "size": 8,
                     "s3-metadata": {
                     "Cache-Control": "s-maxage=31536000, max-age=300"
                      }
                     }
                     """% (end_pnt, end_file))
                 valence_upload(full_file_path,end_file,end_pnt) # send file path to be uploaded
             else:
                 print colored(full_file_path+" has an issue, possibly bad filename\n",'red')
                 return


#----------------------------------------------------------------------------------------------------------------

# Store the list of files and endpoints options from argv
try:
    script, list_of_files_to_upload, list_of_endpoints = argv
except:
    sys.exit("Usage: ./uploader.py list_of_files_or_dirs list_of_endpoints\n")
# Nested loop to iterate through endpoints and list of files
with open(list_of_endpoints) as endpoints:
    with open(list_of_files_to_upload) as filenames:
      for end_pnt in iter(endpoints):
        end_pnt = end_pnt.rstrip()
        for line in iter(filenames):
            line = line.rstrip()
            end_file = "/"+get_end_path(line)
            is_file = os.path.isfile(line)
            is_dir = os.path.isdir(line)
            if os.path.isfile(line):
                with open("META.json","w") as META:
                             META.write(
                     """
                     {
                     "endpoint": "%s%s",
                     "application": "MT",
                     "user": "ababyrev",
                     "tier": "prod",
                     "ttl": 3600,
                     "size": 8,
                     "s3-metadata": {
                     "Cache-Control": "s-maxage=31536000, max-age=300"
                      }
                     }
                     """%(end_pnt,end_file))
                valence_upload(line,end_file,end_pnt)

            elif os.path.isdir(line):
                upload_directory_contents(line,end_pnt)

            else:
                print line+" is: "+str(is_file).strip()

if os.path.isfile("temp_s3_uploaded.log"):

    timestr = time.strftime("%m-%d-%Y-%H-%M-%S")
    os.rename("temp_s3_uploaded.log", "s3_uploaded-"+timestr+".log")

if os.path.isfile("temp_s3_rejected.log"):

    timestr = time.strftime("%m-%d-%Y-%H-%M-%S")
    os.rename("temp_s3_rejected.log", "s3_rejected-"+timestr+".log")

