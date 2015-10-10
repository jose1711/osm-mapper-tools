#!/usr/bin/env python2
# regadr2osm
# skonvertuje xml subor ziskany zo sluzby register adries (http://www.minv.sk/?register-adries)
# do osm suboru
#
# ocakava jediny argument: xml subor z datovej schranky

import xml.etree.ElementTree as ET
from xml.dom import minidom
import sys, os


def prettify(elem):
    """Return a pretty-printed XML string for the Element.
    """
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")

inputfile = sys.argv[1]
tree = ET.parse(inputfile)
root = tree.getroot()
newroot = ET.fromstring('''<osm generator="Python 2.x" version="0.6"></osm>''')
ns='http://www.egov.sk/mvsr/RA/Odpis/Ext/ObjednanieDatasetuAdresnychBodovBezZepUI.1.0'
counter = 0

for i in root.iter():
	if i.tag.endswith('item') and '{{{0}}}addressPoint'.format(ns) in [x.tag for x in i.iter()]:
		counter += 1
		street=i.findall('./{{{0}}}streetName/{{{0}}}name'.format(ns))[0].text
		streetn = i.findall('./{{{0}}}buildingNumber'.format(ns))[0].text
		conscrn = i.findall('./{{{0}}}propertyRegistrationNumber'.format(ns))[0].text
		city = i.findall('./{{{0}}}district/{{{0}}}itemName'.format(ns))[0].text
		
		lat = i.findall('./{{{0}}}addressPoint/{{{0}}}BLH/{{{0}}}axisB'.format(ns))[0].text
		lon = i.findall('./{{{0}}}addressPoint/{{{0}}}BLH/{{{0}}}axisL'.format(ns))[0].text

		node = ET.SubElement(newroot, 'node')
		node.set("id",str(counter*-1))
		node.set("visible",'true')
		node.set("lat",lat)
		node.set("lon",lon)
		citytag = ET.SubElement(node, 'tag')
		streettag = ET.SubElement(node, 'tag')
		streetntag = ET.SubElement(node, 'tag')
		conscrntag = ET.SubElement(node, 'tag')
		housenutag = ET.SubElement(node, 'tag')
		citytag.set("k","addr:city")
		citytag.set("v",city)
		streettag.set("k","addr:street")
		streettag.set("v",street)
		streetntag.set("k","addr:streetnumber")
		streetntag.set("v",streetn)
		conscrntag.set("k","addr:conscriptionnumber")
		conscrntag.set("v",conscrn)
		housenutag.set("k","addr:housenumber")
		housenutag.set("v",u'{}/{}'.format(conscrn,streetn))

		print u'{0} {2}/{1}: {3} {4}'.format(street,streetn, conscrn, lat, lon).encode('utf-8')

newtree = ET.ElementTree(newroot)
with open(os.path.splitext(inputfile)[0]+'.osm', 'w') as outfile:
	outfile.write(prettify(newroot).encode('utf-8'))
