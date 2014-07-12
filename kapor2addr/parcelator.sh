#!/bin/bash
#set -x
# taken from: wiki.freemap.sk
if [[ $1 ]] && [[ $2 ]] && [[ $2 ]]
then
obec=$1
meno_obce=$2
# do not put psc in osm file(s)
psc=$3
psc=
parcely=${obec}_parcely.txt
noparcely=${obec}_neexistuju_parcelne_koordinaty.csv
zoznam=${obec}_adresne_body.csv

rm -f ${noparcely}

nLines=`wc -l <${obec}_adresne_body.csv`

for nLine in `seq 1 1 $nLines`;
do

line=`sed -n ${nLine}p ${zoznam}`


ulica=`echo $line|cut -d, -f1|sed 's/"//g'`
orientacne=`echo $line|cut -d, -f3|sed 's/"//g'`
supisne=`echo $line|cut -d, -f2|sed 's/"//g'`
parcela=`echo $line|cut -d, -f4|sed 's/"//g'`
name=`echo $line|cut -d, -f5|sed 's/"//g'`
out=`echo ${ulica}.osm|sed 's/\ /_/g'`

echo "line is: $line, orientacne: $orientacne, supisne: $supisne, parcela: $parcela"

if [ -z "${parcela}" ] 
	then
	parcela="xxxx"
	fi

if ! grep -q ^${parcela}\| ${parcely}
then
    if grep -q ^${parcela}\/ ${parcely}
    then
        parcela=`grep ^${parcela}\/ ${parcely}|cut -d\| -f1|head -n 1`
    else    
        parcela=`echo ${parcela}|sed 's/\(.*[0-9]*\)\/.*/\1/'`
        if ! grep -q ^${parcela}\| ${parcely}
        then
            echo "$line" >> neexistuju_parcelne_koordinaty.csv;
            continue
        fi
    fi
fi

for latlot in `grep ^$parcela\| $parcely|awk -F\| '{print $2"_"$3}'`
do
latitude=`echo $latlot|awk -F_ '{print $2}'`
longitude=`echo $latlot|awk -F_ '{print $1}'`

if [[ ${name} ]]
then
    #echo "<node id='-"$nLine"' visible='true' lat='"$latitude"' lon='"$longitude"'><tag k='addr:city' v='"${meno_obce}"'/><tag k='addr:conscriptionnumber' v='"$supisne"' /><tag k='addr:country' v='SK' /><tag k='addr:housenumber' v='"$supisne"/"$orientacne"' /><tag k='addr:postcode' v='"${psc}"' /><tag k='addr:street' v='"$ulica"' /><tag k='addr:streetnumber' v='"$orientacne"' /></node>" >> ${out}
    echo "<node id='-"$nLine"' visible='true' lat='"$latitude"' lon='"$longitude"'><tag k='addr:city' v='"${meno_obce}"'/><tag k='addr:conscriptionnumber' v='"$supisne"' /><tag k='addr:country' v='SK' /><tag k='addr:housenumber' v='"$supisne"/"$orientacne"' /><tag k='addr:street' v='"$ulica"' /><tag k='addr:streetnumber' v='"$orientacne"' /></node>" >> ${out}
    echo "<node id='-"$nLine"' visible='true' lat='"$latitude"' lon='"$longitude"'><tag k='name' v='"$name"'/></node>" >> names.osm
else
    #echo "<node id='-"$nLine"' visible='true' lat='"$latitude"' lon='"$longitude"'><tag k='addr:city' v='"${meno_obce}"'/><tag k='addr:conscriptionnumber' v='"$supisne"' /><tag k='addr:country' v='SK' /><tag k='addr:housenumber' v='"$supisne"/"$orientacne"' /><tag k='addr:postcode' v='"${psc}"' /><tag k='addr:street' v='"$ulica"' /><tag k='addr:streetnumber' v='"$orientacne"' /></node>" >> ${out}
    echo "<node id='-"$nLine"' visible='true' lat='"$latitude"' lon='"$longitude"'><tag k='addr:city' v='"${meno_obce}"'/><tag k='addr:conscriptionnumber' v='"$supisne"' /><tag k='addr:country' v='SK' /><tag k='addr:housenumber' v='"$supisne"/"$orientacne"' /><tag k='addr:street' v='"$ulica"' /><tag k='addr:streetnumber' v='"$orientacne"' /></node>" >> ${out}
fi

done

done
for osm_files in *.osm
do
echo "<?xml version='1.0' encoding='UTF-8'?><osm version='0.6'>"> tmp.osm
cat $osm_files >> tmp.osm
echo "</osm>" >>tmp.osm
mv tmp.osm $osm_files
done
else
echo "pouzitie: ./${0} nazov_obce \"Nazov Obce s diakritikov\" \"PSC\""
echo "nazov_obce cast pouzita v navoch suborov"
echo "Nazov Obce s diakritikou sa pouziva v osm ako addr:city"
echo "PSC: pouziva sa ako addr:postcode"
echo "vstupne subory: nazov_obce_parcely.txt"
echo "nazov_obce_adresne_body.csv - dodany zoznam formatovany nasledovne:"
echo "\"ulica\",\"orientacne\",\"supisne\",\"parcela\",\"nazov objektu(nemus byt)\""
echo
echo "Vystup: pre kazdu ulicu: nazov_ulice.osm"
echo "ak existuju nazvy: names.osm"
fi
