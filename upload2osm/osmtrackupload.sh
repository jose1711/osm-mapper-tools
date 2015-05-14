#!/bin/bash
user=user@server.tld
password=password
tags=slovakia

description=$1
shift

for i
        do
        echo $i
curl -u ${user}:${password} -H "Expect: " -F "file=@$i" -F description="${description}" \
   -F tags=${tags} -F visibility=identifiable http://www.openstreetmap.org/api/0.6/gpx/create
done

exit 0

