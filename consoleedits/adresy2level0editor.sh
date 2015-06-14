#!/bin/bash
# pulls a txt file converted from osm file using osmconvert
# from a remote server matching a pattern, then opens it
# in console browser (lynx)
#
# used to fix and expand abbreviated street names in slovakia
#
# recommended way of editing on raspberry pi. tested with raspi 1
#
# accepts three arguments, two of them are optional:
#
# ./adresy2level0editor {pattern} [format] [file]
#
# where
#  pattern = pattern string to search (uses grep pattern-matching)
#  format = if set to josm, lynx is not invoked but instead a series of [nwr]<id> is generated
#           this can be then pasted to josm's download object dialog window
#  file = filename on the remote server
pattern=$1
format=$2
file=adresy_jun12.txt
server=cpi

#######################
if [ ! -z "$3" ]
	then
	file="$3"
	fi
test -z "${format}" && { format="level0" ; }

if [ ${format} == "josm" ]
	then
		ssh ${server} "grep \"${pattern}\" ${file}" | \
		awk -F'\t' '$2 == "node"{type="n"} $2=="way"{type="w"} {printf "%s%s,",type,$1}' | \
		sed 's/,$/\n/'
	else
		ssh ${server} "grep \"${pattern}\" ${file}"  | \
		# too long lines causes issues so splitting at 1000B
		awk -F'\t' '{printf "%s/%s,",$2,$1}{sumlen=sumlen+length($1)+length($2);if (sumlen>1000){sumlen=0;print ""}}'   | \
		sed 's%^%lynx http://level0.osmz.ru/?url=%'   | \
		sed 's/,$/\n/'  | while read -r i
			do
			echo "starting lynx $i"
			eval "$i </dev/null"
			done
	fi
