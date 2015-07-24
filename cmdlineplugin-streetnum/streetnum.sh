#!/bin/bash
#set -x
# bash script for JOSM's commandline plugin that takes value of addr:housenumber
# and puts it into either addr:streetnumber or addr:conscriptionnumber
#
# probably only useful for czech/slovak users
#
# how to install:
#  - enable CommandLine plugin in JOSM
#  - copy this script and related xml file to %appdata%/JOSM/plugins/CommandLine (Windows)
#    or ~/.josm.plugins/CommandLine (Linux)
#  - on Windows: install Cygwin or try win-bash (beware, the script has only been tested on Linux) 
#
# example use:
# 1. in JOSM: select nodes with addr:housenumber and w/o addr:streetnumber/addr:conscriptionnumber:
#    ctrl-f "addr:housenumber" AND "addr:streetnumber"=""
#         OR
#    ctrl-f "addr:housenumber" AND "addr:conscriptionnumber"=""
# 2. in JOSM's CommandLine plugin: type streetnum
# 3. type 0 for housenumber --> conscriptionnumber or type 1 (default) for housenumber --> streetnumber
# 4. check output before upload
#
# known issues:
#  - it's slow. if you want speed, rewrite this in perl or use tagcalc (bundled with CommandLine plugin)

TMPIN=$(mktemp)
TMPPROC=$(mktemp)
TMPOUT=$(mktemp)

putstreetnumber=0

if [ $1 -eq 1 ]
	then
	putstreetnumber=1
	fi
	

# we better save the input into a file for further processing
cat > ${TMPIN}

( while read -r i
	do
	echo "$i" | grep -q "</osm>" && break
	done
cat > ${TMPPROC} ) < ${TMPIN}

# initiate counter
c=0
while read -r i; do
	line=$i
	#line=$(echo "$i" | sed 's/\(.*\(way\|node\) id='\''[0-9]*'\''\).* [^/]>$/\1 action='\''modify'\''/')
	line=$(echo "$i" | sed 's/\(.*\(way\|node\) id='\''[0-9-]*'\''\)\(.*\)\([^/]\)>/\1 action='\''modify'\''\3\4>/')
	housenum=$(echo "$i" | sed -n '/addr:housenumber/s/.*addr:housenumber'\'' v='\''\([^'\'']*\)'\''.*/\1/p')
	if echo "$i" | grep -q addr:housenumber; then
		if [ "${putstreetnumber}" -eq 1 ]
			then
			echo "<tag k='addr:streetnumber' v='${housenum}' />"
			else
			echo "<tag k='addr:conscriptionnumber' v='${housenum}' />"
			fi
		c=$((c+1))
	fi
echo "$line"
done < ${TMPPROC} > ${TMPOUT}
cat ${TMPOUT}
echo "<!-- Finished! ($c tags added, in $SECONDS seconds) -->"
mv ${TMPOUT} ${TMPOUT}.old
