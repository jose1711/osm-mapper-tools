#!/usr/bin/python2
import math
import sys
import os
import re
import datetime
import argparse

# ARRAY = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~'
ARRAY = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_@'


def string2geo(s):
    """
    converts string into (lat,lon) tuple
    """
    code = 0
    for i in range(len(s)):
        try:
            digit = ARRAY.index(s[i])
        except:
            # not sure where the ~ vs @ came from but this is to accept both
            if s[i] == "~":
                digit = 63
            else:
                raise ValueError

        code = (code << 6) | digit

    # align to 64bit integer
    code = (code << (62 - (6 * len(s))))
    x = y = 0

    # deinterleaving
    for i in range(61, -1, -2):
        x = (x << 1) | ((code >> i) & 1)
        y = (y << 1) | ((code >> (i - 1)) & 1)

    lat = (y << 1) / (2 ** 32 / 180.0) - 90
    lon = (x << 1) / (2 ** 32 / 360.0) - 180

    return (lat, lon)

aparser = argparse.ArgumentParser()
aparser.add_argument('-s', nargs=1, help='Only convert STRING and output to stdout', metavar='STRING')
args = aparser.parse_args()

if args.s:
    print string2geo(args.s[0])
    sys.exit()

# process files in current directory
files = []
waypoints = []
for (dirpath, dirnames, filenames) in os.walk('.'):
    files.extend(filenames)
    break

files.sort(key=lambda x: os.stat(x).st_mtime)

# init. counter
c = 0

# grep for files matching 3gp extension
audiofiles = filter(lambda x: re.search(r'\.3gp$', x), files)

if not audiofiles:
    sys.exit(0)

print "<?xml version='1.0' encoding='UTF-8'?>"
print "<gpx version='1.1' creator='osmand2gpx.py' xmlns='http://www.topografix.com/GPX/1/1'>"


for string in map(lambda x: re.sub("(.*)\.3gp", r"\1", x), audiofiles):
    basename = string
    # string=re.sub("-","",string)
    string = re.sub("-.*", "", string)
    lat, lon = string2geo(string)

    c += 1

    os.system('ffmpeg -y -i ' + basename + '.3gp ' + basename + '.3gp.wav')
    times = (os.stat(basename + '.3gp').st_mtime, os.stat(basename + '.3gp').st_mtime)
    os.utime(basename + '.3gp.wav', times)
    waypoints.append([lon, lat, basename, c, times[0]])

if len(waypoints) < 1:
    sys.exit(0)

for wpt in waypoints:
    lon = wpt[0]
    lat = wpt[1]
    basename = wpt[2]
    name = wpt[3]
    time = wpt[4]
    print "<wpt lon='" + repr(lon) + "' lat='" + repr(lat) + "'>"
    print "<time>" + str(datetime.datetime.fromtimestamp(time)).replace(' ', 'T') + 'Z' + "</time>"
    print "<name>" + repr(name) + "</name>"
    print "<link href='" + basename + ".3gp.wav'/>"
    print "</wpt>"

print "<trk><trkseg>"

for wpt in waypoints:
    lon = wpt[0]
    lat = wpt[1]
    basename = wpt[2]
    name = wpt[3]
    time = wpt[4]
    print "<trkpt lon='" + repr(lon) + "' lat='" + repr(lat) + "'>"
    print "<time>" + str(datetime.datetime.fromtimestamp(time)).replace(' ', 'T') + 'Z' + "</time>"
    print "</trkpt>"

print "</trkseg></trk>"
print "</gpx>"
