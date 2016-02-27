#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
syncs address data between osm and municipality
most likely only usable for slovak openstreetmap community

usage:
 usage: syncer.py [-h] (-f OSM_DUMP | -i RELATION_ID) [-p] [-r] [-u] [-d] municipality_data.csv

local csv files need to be formatted as follows:
 cadastral_area_code<tab>streetname<tab>conscriptionnumber<tab>streetnumber<tab>description (optional)
 <currently unused>      <utf8 encoded>
"""

import sys, os, re, csv, argparse, string, time, io
from unidecode import unidecode

def main():
	pattfile = "patterns.txt"
	pattdata = []
	streetdata = {}
	muni = AddressData(args.munilist[0], 'muni', '1.1.2016')
	if args.osm_dump:
		osm = AddressData(args.osm_dump[0], 'osm', '1.1.2016')
	else:
		osm = AddressData(args.relation_id[0], 'osm', '1.1.2016')

	muni.loaddata()
	osm.loaddata()

	try:
		with open(pattfile) as pattf:
			while True:
				pattern=pattf.readline().rstrip()
				if not pattern:
					break
				compiledpattern=re.compile('.*'+pattern+'.*')
				pattdata.append(compiledpattern)
				streetdata[str(compiledpattern)]=[set([]),set([])]
	except FileNotFoundError:
		print("File containing streetname pattern (%s) does not exist!" % pattfile)
		sys.exit(1)

	muni.findpattern(pattdata)
	osm.findpattern(pattdata)

	if args.unmatched_only:
		sys.exit(0)

	for pattern in pattdata:
		if not args.reversed:
			difference=muni.return_streetnumbers_for_pattern(pattern)-osm.return_streetnumbers_for_pattern(pattern)
			src = muni
		else:
			difference=osm.return_streetnumbers_for_pattern(pattern)-muni.return_streetnumbers_for_pattern(pattern)
			src = osm

		if args.debug_mode:
			print ("difference: %s" % difference)

		difference = set([x for x in difference if x != ""])
		if len(difference):
			for diff in difference:
				for m in src:
					if pattern == m[5] and diff == m[3]:
						if args.debug_mode:
							print("found match for %s %s" % (m[5], m[3]))
						if m[2]:
							m[2] = m[2]+"/"
						if m[4]:
							m[4] = " ("+m[4]+")"
						print ('{street} {conscriptionnumber}{streetnumber}{notes}'.format(street=m[0],streetnumber=diff,conscriptionnumber=m[2],notes=m[4]))
						break

class AddressData:
	"""
	object holding address data from a specified source (municipality or openstreetmap)
	"""
	def __init__(self, srcFile, dataSrc, dateOfOrigin):
		self._srcFile = srcFile
		self._dataSrc = dataSrc
		self._dateOfOrigin = dateOfOrigin
		self._addrData = []
		self._alph = string.ascii_lowercase
		#self._areaCode = areaCode

	def loaddata(self):
		"""
		open file and put parsed data to self._addrData list
		self._addrData.append([street,streetnorm,conscriptionnumber,element,notes])
		"""
		if args.relation_id and self._dataSrc == 'osm':
			if args.debug_mode:
				print ("downloading relation id %s from polygons.openstreetmap.fr" % self._srcFile)
			import requests
			req = requests.get('http://polygons.openstreetmap.fr/?id='+str(self._srcFile))
			while req.status_code != 200:
				time.sleep(1)
			req = requests.get('http://polygons.openstreetmap.fr/get_poly.py?id='+str(self._srcFile)+'&params=0')
			poly = [x.replace('\t',' ') for x in req.text.split('\n') if x not in '["polygon","END"]' and x != "1" ]
			poly = ' '.join([' '.join([x.split(' ')[2],x.split(' ')[1]]) for x in poly])
			postdata='[out:csv("addr:street",'
			if args.addrplace:
				postdata+='"addr:place",'
			postdata+='"addr:conscriptionnumber","addr:streetnumber")];'
			postdata+='(node["addr:streetnumber"](poly:"'+poly+' ");'
			postdata+='way["addr:streetnumber"](poly:"'+poly+' ");'
			postdata+='relation["addr:streetnumber"](poly:"'+poly+' ");'
			if args.addrplace:
				postdata+='node["addr:place"](poly:"'+poly+' ");'
				postdata+='way["addr:place"](poly:"'+poly+' ");'
				postdata+='relation["addr:place"](poly:"'+poly+' ");'
			postdata+='<;);out;'
			if args.debug_mode:
				print ("overpass query: {}".format(postdata))
			x = requests.post('http://overpass-api.de/api/interpreter', postdata)
			x.encoding = 'UTF-8'
			content = ["ignore\t"+x+"\tignore" for x in x.text.split("\n") if x != ""][1:]
			if args.addrplace:
				templist = []
				for x in content:
					entry = x.split('\t')
					# if addr:street is empty but addr:place exists then use addr:place instead
					if not entry[1] and entry[2]:
						templist.append([entry[0]]+[entry[2]]+entry[3:])
					else:
						templist.append(entry[0:2]+entry[3:])
				
				content = ['\t'.join(x) for x in templist]
			content='\n'.join(content)
			if args.debug_mode:
				print (content)
			f = io.StringIO(content)
		else:
			f = open(self._srcFile)	
		
		municsvreader = csv.reader(f, delimiter='	', quotechar='"')
		for line in municsvreader:
			if len(line) < 5:
				line.extend([''])
			# cut off trailing whitespace characters in each column
			line=[x.rstrip() for x in line]
			try:
				(ignore,street,conscriptionnumber,streetnumber,notes)=line
			except:
				print("error on %s" % line)
				continue
				#raise IOError
			# normalize streetname: "Žltá" becomes "zlta"
			streetnorm=str.lower(unidecode(street))
			# normalize street number: "39/ A" becomes "39a"
			streetnumber=str.lower(streetnumber).replace('/','').replace(' ','')
			# split into chunks using comma as a separator
			for element in re.findall('([^,]+)',streetnumber):
				# break 10a-10d into independent elements (10a, 10b, 10c and 10d)
				if re.match(r'^([0-9]+)[a-z]-\1?[a-z]$',element):
					match=re.match(r'^([0-9]+)([a-z])-\1?([a-z])',element)
					start = match.group(2)
					end = match.group(3)
					for char in self._alph[self._alph.index(start):self._alph.index(end)+1]:
						self._addrData.append([street,streetnorm,conscriptionnumber,match.group(1)+char,notes])
				else:
					self._addrData.append([street,streetnorm,conscriptionnumber,element,notes])

	def findpattern(self, pattdata):
		addrDataNew = []
		unmatched = set([])
		for street,streetnorm,conscriptionnumber,streetnumber,notes in self._addrData:
			for pattern in pattdata:
				if pattern.match(streetnorm):
					addrDataNew.append([street,streetnorm,conscriptionnumber,streetnumber,notes,pattern])
					break
			else:
				if args.unmatched_only:
					unmatched.update([streetnorm])
				else:
					print ('"{}" is not matched ({})'.format(streetnorm,self._srcFile))
		self._addrData = addrDataNew	
		if args.unmatched_only and len(unmatched) > 0:
			for nonmatch in sorted(unmatched):
				print (nonmatch)

	def return_streetnumbers_for_pattern(self, desiredpattern):
		streetnumbers = set([])
		for street,streetnorm,conscriptionnumber,streetnumber,notes,pattern in self._addrData:
			if pattern == desiredpattern:
				streetnumbers.update([streetnumber])
		return streetnumbers

	def __iter__(self):
		self.pointer = -1
		return self
			
	def __next__(self):
		self.pointer += 1
		try:
			return self._addrData[self.pointer]
		except:	
			raise StopIteration
			

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description='Shows difference between data from municipality and OSM')
	group1 = parser.add_mutually_exclusive_group(required=True)
	group1.add_argument('-f', dest='osm_dump', type=str, nargs=1, help='osm dump read from a local csv file')
	group1.add_argument('-i', dest='relation_id', type=int, nargs=1, help='osm data read from overpass turbo')
	parser.add_argument('munilist', metavar='muni', type=str, nargs=1, help='csv file containing data from municipality')
	parser.add_argument('-r', dest='reversed', action='store_true', help='reverse query: which data are in OSM but are missing in list from municipality')
	parser.add_argument('-u', dest='unmatched_only', action='store_true', help='only show unmatched street names')
	parser.add_argument('-p', dest='addrplace', action='store_true', help='use value of addr:place if addr:street is empty')
	parser.add_argument('-d', dest='debug_mode', action='store_true', help='show some debug info')
	args = parser.parse_args()

	main()
