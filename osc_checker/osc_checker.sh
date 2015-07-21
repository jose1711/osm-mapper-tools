#!/bin/bash
# runs various checks on osm change file
# allowing to spot errors and notify author
# of a problematic changeset
#
#                         please share your thoughts
#                             jose1711 gmail com
#
# tests are not overly complicated - for more
# complex ones there's postgis or similar tool
#
# requirements:
#  - xmllint
#  - wget
# invocation:
#  ./osc_checker.sh {filename.osc or sequence number | latest}
#
# note: latest is a keyword which indicates that the freshest
#       osc file on geofabrik server should be pulled
#
# if sequence number is specified, the osm changefile
# is downloaded from geofabrik
#
# known problems:
# geofabrik's osm change files are not precisely cut on
# borders so you may encounter some false positives. 


geofabrik_url=http://download.geofabrik.de/europe/slovakia-updates/000/000/
geofabrik_state=http://download.geofabrik.de/europe/slovakia-updates/state.txt
tmpdir=/tmp

function label {
label=$1
cat <<HERE
------------------------
${label}
------------------------
HERE
}

input=$1

which xmllint >/dev/null 2>&1
if [ $? -ne 0 ]
	then
	echo "xmllint is not installed or not in PATH"
	exit 1
	fi

if [ -z "${input}" ]
	then
	echo "you need to specify argument: filename.osc or sequence number"
	exit 1
	fi

if [ ! -f "${input}" -a "${input}" = "latest" ]
	then
    input=$(wget -qO- "${geofabrik_state}" | awk -F= '/sequenceNumber/ {print $2}')
	fi

if [ ! -f "${input}" -a "${input}" -gt 1 ]
	then
	echo "input will be pulled from web"
	wget -qO "${tmpdir}/${input}" ${geofabrik_url}/${input}.osc.gz
	input="${tmpdir}/${input}"
	if [ ! -s "${input}" ]
		then
		echo "failed to download sequence"
		exit 1
		fi
	fi

label "if housenumber contains slash (/) then both conscriptionnumber and streetnumber must exist"
xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*[./tag[@k="addr:housenumber"][contains(@v,"/")] and ( not(./tag[@k="addr:streetnumber"]) or not(./tag[@k="addr:conscriptionnumber"]) )]' "${input}" 2>/dev/null | grep -v '<nd ref'

label "if housenumber exists then there must also be a conscriptionnumber and/or streetnumber"
xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*[./tag[@k="addr:housenumber"] and ( not(./tag[@k="addr:streetnumber"]) and not(./tag[@k="addr:conscriptionnumber"]) )]' "${input}"  2>/dev/null | grep -v '<nd ref'

label "housenumber should not contain string matching /[A-Za-z]" 
xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*/tag[@k="addr:housenumber"]/@v' "${input}" 2>/dev/null | sed 's/v="/\n/g' | grep -E '/[A-Za-z]' | tr -d '"' | while read -r value
	do
	xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*[./tag[@k="addr:housenumber"][@v="'${value}'"]]' "${input}" 2>/dev/null | grep -v '<nd ref'
	done

label "housenumber may only contain numbers, slash and an optional single uppercase letter" 
xmllint --xpath  '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*/tag[@k="addr:housenumber"]/@v' "${input}" 2>/dev/null | sed 's/v="/\n/g' | tr -d '"' | sed -e 's/^ *//' -e 's/ $//' | grep -Ev '^[1-9][0-9]*([A-Z]?$|/[1-9][0-9]*?[[:upper:]]?$)' | while read -r value
	do
	xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*[./tag[@k="addr:housenumber"][@v="'${value}'"]]' "${input}" 2>/dev/null | grep -v '<nd ref'
	done

label "addr:conscriptionnumber may only contain number"
xmllint --xpath  '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*/tag[@k="addr:conscriptionnumber"]/@v' "${input}" 2>/dev/null | sed 's/v="/\n/g' | tr -d '"' | sed -e 's/^ *//' -e 's/ $//' | grep -Ev '^[1-9][0-9]*$' | while read -r value
	do
	xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*[./tag[@k="addr:conscriptionnumber"][@v="'${value}'"]]' "${input}" 2>/dev/null | grep -v '<nd ref'
	done

label "addr:streetnumber may only contain number and an optional single uppercase letter"
xmllint --xpath  '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*/tag[@k="addr:streetnumber"]/@v' "${input}" 2>/dev/null | sed 's/v="/\n/g' | tr -d '"' | sed -e 's/^ *//' -e 's/ $//' | grep -Ev '^[1-9][0-9]*[[:upper:]]?$' | while read -r value
	do
	xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*[./tag[@k="addr:streetnumber"][@v="'${value}'"]]' "${input}" 2>/dev/null | grep -v '<nd ref'
	done

label "if there's addr:conscriptionnumber without addr:streetnumber, then there should also be addr:place"
xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*[./tag[@k="addr:conscriptionnumber"] and not(./tag[@k="addr:streetnumber"]) and not(./tag[@k="addr:place"]) ]' "${input}" 2>/dev/null | grep -v '<nd ref'

label "addr:streetnumber requires addr:street tag"
xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*[./tag[@k="addr:streetnumber"] and not(./tag[@k="addr:street"]) ]' "${input}" 2>/dev/null | grep -v '<nd ref'

label "addr:postcode contains 6 numbers with an optional space"
xmllint --xpath  '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*/tag[@k="addr:postcode"]/@v' "${input}" 2>/dev/null | sed 's/v="/\n/g' | tr -d '"' | sed -e 's/^ *//' -e 's/ $//' | grep -Ev '^[0-9][0-9][0-9] ?[0-9][0-9]$' | while read -r value
	do
	xmllint --xpath '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*[./tag[@k="addr:postcode"][@v="'${value}'"]]' "${input}" 2>/dev/null | grep -v '<nd ref'
	done

label "buzzwords (ad) detected?"
xmllint --xpath  '/osmChange/*[not(contains(string(local-name(.)),"delete"))]/*' "${input}" 2>/dev/null | grep -iE 'prekrásn|malebn|ceny|lacn'

echo
