#!/bin/bash
source functions.sh
dbname=$1
url=http://download.geofabrik.de/europe/slovakia-latest.osm.bz2
#url=http://download.geofabrik.de/europe/czech-republic-latest.osm.bz2

scriptdir="$( cd "$( dirname "$0" )" && pwd )"

if [ -z "${dbname}" ]
        then
        echo "Supply dbname as the only argument"
        echo "Example: $0 testdb"
        exit 1
        fi

if [ $(id -u) -ne 0 ]
	then
	echo "Please rerun as root user"
	exit 1
	fi

extraarg=""
osmosis --read-empty --un idTrackerType=Dynamic --wn
if [ $? -eq 0 ]
    then
    extraarg="idTrackerType=Dynamic"
    fi

delete_all_data_public_scheme || exit 1

# import bodov a ciest z geofabriku
echo "Creating and flushing fifos"
[ -p /tmp/fifo1 ] || mkfifo /tmp/fifo1 || { echo "Terminated with error"; exit 1; }
[ -p /tmp/fifo2 ] || mkfifo /tmp/fifo2 || { echo "Terminated with error"; exit 1; }
dd if=/tmp/fifo1 iflag=nonblock of=/dev/null
dd if=/tmp/fifo2 iflag=nonblock of=/dev/null
echo "Converting"
osmosis --rx file=/tmp/fifo1 --nk keyList="addr:housenumber,addr:streetnumber,addr:conscriptionnumber" --wb file=/tmp/housenumbers_nodes.osm.pbf &
osmosis --rx file=/tmp/fifo2 --wk keyList='addr:housenumber,addr:streetnumber,addr:conscriptionnumber' --tf reject-relations --un ${extraarg} --wb file=/tmp/housenumbers_ways.osm.pbf &
curl -s "${url}" | bunzip2 - | tee /tmp/fifo1 | tee /tmp/fifo2 | pv >/dev/null
wait
echo "Download done, import starts in 10 seconds"
ls -l /tmp/housenumbers_nodes.osm.pbf /tmp/housenumbers_ways.osm.pbf
sleep 10
osmosis --rb file=/tmp/housenumbers_nodes.osm.pbf outPipe.0=IN1 \
	--rb file=/tmp/housenumbers_ways.osm.pbf outPipe.0=IN2 \
	--merge inPipe.0=IN1 inPipe.1=IN2 \
	--write-pgsql host="localhost" user="postgres" database="${dbname}" password="postgres"
echo "Import done"

rm /tmp/fifo1 /tmp/fifo2

# extract and import of hiking routes relations only:
#curl -s http://download.geofabrik.de/europe/slovakia-latest.osm.bz2 | bunzip2 - | osmosis --rx file=- --tf accept-relations 'route=hiking' --uw --un ${extraarg} --wb file=hiking_routes.osm.pbf

# same with public transportation
#curl -s http://download.geofabrik.de/europe/slovakia-latest.osm.bz2 | bunzip2 - | osmosis --rx file=- --tf accept-relations 'route=tram,bus' --uw ${extraarg} --un ${extraarg} --wb file=public_transport_routes.osm.pbf

