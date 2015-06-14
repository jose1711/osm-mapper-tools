#!/bin/bash
set -e
set -u
dbname=$1
nad2bin < slovak.lla /tmp/slovak
sudo cp /tmp/slovak /usr/share/proj
cp ./sjtk2postgis.sql /tmp
sudo su - postgres -c "psql -d ${dbname} -f /tmp/sjtk2postgis.sql"
