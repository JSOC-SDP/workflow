#! /bin/csh -f 
# This script creates the HARP 720s definitive web images. Each image is a superposition of all HARP images that have been observed
# on a given day.

set SCRTREE = /home/jsoc/cvs/Development/JSOC
set SCRIPT = proj/mag/harp/scripts/track_hmi_harp_movie_driver.sh
set MASKSERIES = hmi.Marmask_720s
set HARPSERIES = hmi.Mharp_720
set OUTDIR = /web/jsoc/htdocs/doc/data/hmi/harp/harp_definitive

# Must fetch low and high from gate state files. Assume the working directory is the harp-images gate directory.
set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

# Must round down to the nearest hour. I have no clue how you'd do this in csh, so I'm doing this in perl.
# Assume that at least the hour field is present.
set low = `perl -e 'my($wantlow) = "'$wantlow'"; if ($wantlow =~ /^\s*(\d\d\d\d)\.(\d+)\.(\d+)_(\d+)(.*)/) { my($pref) = sprintf("%4d", $1) . "\." . sprintf("%02d", $2) . "\." . sprintf("%02d", $3) . "_" . sprintf("%02d", $4); my($suff) = $5; my($tz) = ""; if ($suff =~ /^[^_]*_(\S+)/) {$tz = "_$1"; } print "$pref:00:00$tz"; }'`

set high = `perl -e 'my($wanthigh) = "'$wanthigh'"; if ($wanthigh =~ /^\s*(\d\d\d\d)\.(\d+)\.(\d+)_(\d+)(.*)/) { my($pref) = sprintf("%4d", $1) . "\." . sprintf("%02d", $2) . "\." . sprintf("%02d", $3) . "_" . sprintf("%02d", $4); my($suff) = $5; my($tz) = ""; if ($suff =~ /^[^_]*_(\S+)/) {$tz = "_$1"; } print "$pref:00:00$tz"; }'`

$SCRTREE'/'$SCRIPT -f $MASKSERIES'['$low'-'$high'@1h]' $HARPSERIES $OUTDIR
