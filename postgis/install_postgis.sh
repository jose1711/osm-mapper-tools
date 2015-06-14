#!/bin/bash
if [ $(id -u) -ne 0 ]
	then
	echo "Please rerun as root user"
	exit 1
	fi

distro=$(lsb_release -i 2>/dev/null | awk -F'\t' '{print $NF}')
case "$distro" in 
	Debian) echo "Debian-based distribution detected"
	apt-get update
	apt-get install postgis postgresql-contrib-9.1 osmosis gdal-bin gpsbabel pv postgresql-9.1-postgis
		;;
	Arch) echo "ArchLinux distributon detected"	
	pacman -Sy postgis postgresql postgresql-libs pv osmosis gpsbabel gdal
		;;
	*) echo "Unknown distribution (or lsb-release is missing), only Debian or Arch is detected."
		exit 1
		;;
esac

