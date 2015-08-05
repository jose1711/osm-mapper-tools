#!/bin/bash
# reverses gpx file keeping original timestamps
INPUT=$1
CSV=$(mktemp)
CSVREV=$(mktemp)
CSVNEW=$(mktemp)

gpsbabel -t -i gpx -f "${INPUT}" -o unicsv -F "${CSV}"
# remove dos line endings
sed -i -e 's///' -e '/Latitude,Longitude/d' "${CSV}" 
tac <"${CSV}" >"${CSVREV}"
echo "No,Latitude,Longitude,Altitude,Date,Time" > "${CSVNEW}"
paste -d, "${CSV}" "${CSVREV}" | awk -F, '{OFS=",";print $1,$8,$9,$10,$5,$6}' >> "${CSVNEW}"

gpsbabel -t -i unicsv -f "${CSVNEW}" -o gpx -F "${INPUT%.gpx}-reverted.gpx"

rm "${CSV}" "${CSVREV}" "${CSVNEW}"
