#!/usr/bin/python
# -*- coding: utf-8 -*-
# creates colour-addresses mapcss style for josm specially customized for slovak addresses
# palette taken from: http://phrogz.net/css/distinct-colors.html
import sys
import unicodedata
import colorsys
import random
import codecs

# how to cook ulice-3chars.txt:
#  osmfilter32 --keep= --keep-ways="highway=residential" --drop-nodes --drop-relations slovakia-latest.osm >ulice.osm
#  grep '"name"' ulice.osm | sed 's/.* v="\([^"][^"][^"]\).*/\1/' | sort | uniq -c | grep -v '\.' | sort -nrk 1 | awk '{print $2}' >ulice-3chars.txt

print 'meta {title: "Coloured Addresses (sk)v7"; author: "jose1711"; link: "coloured-addresses-slovakia.mapcss"; description: "Style to ease mapping of addresses by colouring streets and houses (based on simon04\'s style)"; }'

f=codecs.open("ulice-3chars.txt","r","utf-8")
combs=[]
lastchar=[]
for line in f.readlines():
	line=line.strip()
	if len(line) < 3:
		line = line+' '
	combs.append(line)
        try:
		if not line[2] in lastchar:
			lastchar.append(line[2])
	except:
		pass

palette=[]
p=open("paleta.phrogz.net")
for line in p.readlines():
	palette.append(line.strip())

# this is another idea that uses random numbers, idea taken from:
#   http://stackoverflow.com/questions/470690/how-to-automatically-generate-n-distinct-colors
#for x in range(0,len(combs)):
  #hue=x*(1.0/len(combs))
  #sat=0.9+random.random()*0.1
  #bri=0.5+random.random()*0.1
  #rgb=colorsys.hsv_to_rgb(hue,sat,bri)
  #palette.append("#"+''.join(map(lambda x:"%02X" % (x*255),rgb)))

for s in combs:
  colourcode=palette.pop(0)
  if len(s) == 3:
    secondarycolour='#'+''.join(map(lambda x:"%02X" % (x*255),(colorsys.hsv_to_rgb(lastchar.index(s[2])*(1.0/len(lastchar)),1,0.5))))
  else:
    secondarycolour='#000000'
  print 'node["addr:street"^="'+s.encode('utf-8')+'"]::halo {color: '+(colourcode.encode('utf-8'))+'; symbol-fill-color: '+(colourcode.encode('utf-8'))+'; symbol-stroke-color: '+secondarycolour.encode('utf-8')+'; symbol-stroke-width: 3; symbol-shape: circle; symbol-size: 30; z-index: -1;}'
  print 'way["name"^="'+s.encode('utf-8')+'"] {color: '+(colourcode.encode('utf-8'))+';}'
  print 'area[building]["addr:street"^="'+s.encode('utf-8')+'"] {color: '+(colourcode.encode('utf-8'))+'; fill-color: '+(colourcode.encode('utf-8'))+'; casing-width: 3; casing-color: '+secondarycolour.encode('utf-8')+' ;}'

