#!/bin/bash
function delete_all_data_public_scheme {
		sudo -S su - postgres -c id </dev/null 2>/dev/null | grep -q postgres
		if [ $? -ne 0 ]
			then
			echo "Unable to switch to postgres user using sudo, cannot do anything"
			exit 1
			fi

		# vymazanie dat zo schemy public (bacha!) - v postgise
		echo "Deleting data"
		sudo su - postgres -c 'psql -d '"${dbname}" <<HERE
		delete from public.users;
		delete from public.ways;
		delete from public.nodes;
		delete from public.way_nodes;
		delete from public.relations;
HERE
		}

