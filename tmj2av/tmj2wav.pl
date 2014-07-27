#!/usr/bin/perl
# synopsis:
#    tmj2wav.pl filename-to-convert.gpx
# history
# - 25.jan 2014:
#   - now also timestamp information is stored into gpx - this makes the marker show up in josm
# - 2.apr 2012:
#   - if more than 1 file found at given coordinates*, a new gpx
#     file is created so that it will open in a new layer in josm
#     (and information is not lost)
#
# * this could happen if gps signal is not available at time of recording
#   and cellId info is used instead

sub print_header {
my $FILE=$_[0];
print $FILE "<?xml version='1.0' encoding='UTF-8'?>\n";
print $FILE "<gpx version='1.1' creator='tmj2wav' xmlns='http://www.topografix.com/GPX/1/1'>\n";
}

sub print_trailer {
my $FILE=$_[0];
print $FILE "</gpx>\n";
}

my @positions=();
my $fcounter=0;

use strict;
use warnings;
open OUT, ">trackmyjourneytemp.gpx";
open(CMD, "ls *amr|");
print_header("OUT");
while (<CMD>) {
chomp;
$_ =~ m/.*?TMJ Audio ([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2}) (.*?) (.*?).amr/;
if ( grep(/^$7:$8$/,@positions) ){
		print "duplicate coordinates found: $7,$8"."\n";
		open OUT2, ">trackmyjourneytemp".$fcounter.".gpx";
		print_header "OUT2";
		print OUT2 "<wpt lat='".$7."' lon='".$8."'>\n";
		print OUT2 "<time>".$1."-".$2."-".$3."T".$4.":".$5.":".$6."Z</time>\n";
		print OUT2 "<name>".$2."-".$3." ".$4.":".$5.":".$6."</name>\n";
		print OUT2 "<link href='".$_.".wav'/>\n";
		print OUT2 "</wpt>\n";
		print_trailer "OUT2";
		close OUT2;
		$fcounter++;
		}
		else
		{
		push @positions,"$7:$8";
		print OUT "<wpt lat='".$7."' lon='".$8."'>\n";
		print OUT "<time>".$1."-".$2."-".$3."T".$4.":".$5.":".$6."Z</time>\n";
		print OUT "<name>".$2."-".$3." ".$4.":".$5.":".$6."</name>\n";
		print OUT "<link href='".$_.".wav'/>\n";
		print OUT "</wpt>\n";
		}
system("ffmpeg -y -i \"".$_."\" \"".$_.".wav\"");
}
print_trailer("OUT");
close OUT;

system("gpsbabel -i gpx -f trackmyjourneytemp.gpx -x transform,trk=wpt -o gpx -F trackmyjourneytempmerged.gpx")
