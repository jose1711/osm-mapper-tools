#!/bin/bash
# takes output of kapor2 plugin for JOSM and creates input file for parcelator.sh
OLDPATH=${PATH}
PATH=${PATH}:.

which osmfilter >/dev/null || which osmfilter32 >/dev/null || {
	echo "Osmfilter(32) is a dependency, quitting"
	exit 1
}

which osmconvert >/dev/null || which osmconvert32 >/dev/null || {
	echo "Osmconvert(32) is a dependency, quitting"
	exit 1
}

which gpsbabel >/dev/null || {
	echo "Gpsbabel is a dependency, quitting"
	exit 1
}

if which osmfilter >/dev/null
	then
	OSMFILTER=`which osmfilter`
	else
	OSMFILTER=`which osmfilter32`
	fi

if which osmconvert >/dev/null
	then
	OSMCONVERT=`which osmconvert`
	else
	OSMCONVERT=`which osmconvert32`
	fi

PATH=${OLDPATH}

# here you can override
#OSMFILTER=
#OSMCONVERT=

echo "Osmfilter is: ${OSMFILTER}, osmconvert is: ${OSMCONVERT}"


# $1 = inputfile (output from kapor2 plugin with export_names enabled)
# $2 = kuzemie (kod)

# (do not forget to clip input file on admin boundaries) -> this is now done automatically
# http://osm102.openstreetmap.fr/~jocelyn/polygons/index.py
# e. g. osmconvert europe.osm.pbf -B=country.poly -o=switzerland.o5m

if [[ $1 ]] && [[ $2 ]]
	then
	infile=$1
	kuzemie=$2
	else
	echo "Invocation: $0 inputfile.osm kod_kuzemia, example:"
	echo "  $0 pn-kapor2export.osm 830000"
	exit 1
fi

outfile="${infile}".proc.osm

echo $kuzemie | grep -qE "8[0-9][0-9][0-9][0-9][0-9]$"
if [ $? -ne 0 ]
	then
	echo "cadastral code seems to be incorrect (8xxxxx)."
	exit 1
	fi

set -x

osmid=$(curl -s 'http://nominatim.openstreetmap.org/search?q='${kuzemie}'&format=json' | grep boundary | tr ',' '\n' | awk -F: '/osm_id/{gsub("\"","",$0);print $2}')
curl -s http://polygons.openstreetmap.fr/?id=${osmid} >/dev/null 2>&1
# give some time to process
sleep 3
curl -s 'http://polygons.openstreetmap.fr/get_poly.py?id='${osmid}'&amp;params=0' > ${kuzemie}.poly

"${OSMCONVERT}" "${infile}" -B=${kuzemie}.poly > "${infile}".clipped


"${OSMFILTER}" "${infile}".clipped --keep= --keep-ways="name=*Parcela*" | sed "s%Parcela: \([0-9/]*\).*%\1\" />%" | "${OSMCONVERT}" - --all-to-nodes --object-type-offset=1500000 --fake-version >"${infile}".tmp
"${OSMFILTER}" "${infile}".tmp --keep="all name=*" --keep-tags="all name=*" >"${outfile}"

gpsbabel -i osm -f "${outfile}"  -o unicsv -F - | tr -d '"' | awk -F, '{print $4"|"$3"|"$2}' | sort -u >${kuzemie}_parcely.txt

rm "${infile}".tmp "${infile}".clipped "${outfile}"
echo "Rename ${kuzemie}_parcely.txt to <<obec>>_parcely.txt"
