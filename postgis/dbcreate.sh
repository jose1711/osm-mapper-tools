#!/bin/bash
dbname=$1

if [ -z "${dbname}" ]
	then	
	echo "Supply name of the db as the only argument"
	echo "Example: $0 testdb"
	exit 1
	fi

if [ $(id -u) -ne 0 ]
	then
	echo "Please rerun as root user"
	exit 1
	fi

distro=$(lsb_release -i 2>/dev/null | awk -F'\t' '{print $NF}')

su - postgres -c "createdb --encoding=UTF8 --owner=postgres ${dbname}"
case ${distro} in
	Debian):
	su - postgres -c "psql -v ON_ERROR_STOP=1 --dbname=${dbname} --file=/usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql"
	su - postgres -c "psql -v ON_ERROR_STOP=1 --dbname=${dbname} --file=/usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql"
	;;
	Arch):
	:
	;;
	*)
	echo "Distribution not recognized, sorry.."
	exit 1
	;;	
esac

# when error about error block encountered try pgsql -d ${dbname} -c "VACUUM FULL"
su - postgres -c "psql -d $dbname -c 'ALTER ROLE postgres with password '\'postgres\''; create extension hstore'"

case ${distro} in
	Debian):
	su - postgres -c "psql -d ${dbname} -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6.sql"
	su - postgres -c "psql -d ${dbname} -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_linestring.sql"
	;;
	Arch):
	:
	;;
	*)
	echo "Distribution not recognized, sorry.."
	exit 1
	;;	
esac
