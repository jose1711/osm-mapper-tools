#!/usr/bin/python2
import math
import sys
import os
import re
import datetime

#ARRAY = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~'
ARRAY = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_@'

# process files in current directory

files = []
waypoints= []
for (dirpath, dirnames, filenames) in os.walk('.'):
  files.extend(filenames)
  break
 
files.sort(key=lambda x:os.stat(x).st_mtime)

# init. counter
c=0

print "<?xml version='1.0' encoding='UTF-8'?>"
print "<gpx version='1.1' creator='osmand2gpx.py' xmlns='http://www.topografix.com/GPX/1/1'>"

# grep for files matching 3gp extension
audiofiles=filter(lambda x:re.search(r'\.3gp$',x),files)

for string in map(lambda x:re.sub("(.*)\.3gp",r"\1",x),audiofiles):
  code=0
  basename=string
  string=re.sub("-","",string)
  for i in range(len(string)):
    try:
      digit = ARRAY.index(string[i])
    except:
# not sure where the ~ vs @ came from but this is to accept both
      if string[i] == "~":
        digit = 63
      else:
        raise ValueError
      
    code = ( code << 6 ) | digit
 
  # align to 64bit integer
  code=( code << (62 - (6 * len(string) ) ) )
  x=y=0
  c+=1
 
  # deinterleaving
  for i in range(61,-1,-2):
    x=(x << 1) | (( code >> i ) & 1)
    y=(y << 1) | (( code >> (i-1) ) & 1)
 
  lon = (x << 1)/(2**32 / 360.0)-180
  lat = (y << 1)/(2**32 / 180.0)-90
 
  os.system('ffmpeg -y -i '+basename+'.3gp '+basename+'.3gp.wav')
  times=(os.stat(basename+'.3gp').st_mtime,os.stat(basename+'.3gp').st_mtime)
  os.utime(basename+'.3gp.wav',times)
  waypoints.append([lon,lat,basename,c,times[0]])
  

for wpt in waypoints:
	lon=wpt[0]
	lat=wpt[1]
	basename=wpt[2]
	name=wpt[3]
	time=wpt[4]
  	print "<wpt lon='"+repr(lon)+"' lat='"+repr(lat)+"'>"
	print "<time>"+str(datetime.datetime.fromtimestamp(time)).replace(' ','T')+'Z'+"</time>"
  	print "<name>"+repr(name)+"</name>"
  	print "<link href='"+basename+".3gp.wav'/>"
  	print "</wpt>"

print "<trk><trkseg>"

for wpt in waypoints:
	lon=wpt[0]
	lat=wpt[1]
	basename=wpt[2]
	name=wpt[3]
	time=wpt[4]
  	print "<trkpt lon='"+repr(lon)+"' lat='"+repr(lat)+"'>"
	print "<time>"+str(datetime.datetime.fromtimestamp(time)).replace(' ','T')+'Z'+"</time>"
  	print "</trkpt>"
	
print "</trkseg></trk>"
print "</gpx>"
