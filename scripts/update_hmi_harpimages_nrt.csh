#! /bin/csh -f 
# This script creates the HARP 720s nrt web images. Each image is a superposition of all HARP images that have been observed
# on a given day.

set SCRTREE = /home/jsoc/cvs/Development/JSOC
set SHOWINFO = $SRCTREE'/'bin/linux_x86_64/show_info
set SCRIPT = proj/mag/harp/scripts/track_hmi_harp_movie_driver.sh
set MASKSERIES = hmi.Marmask_720s_nrt
set HARPSERIES = hmi.Mharp_720_nrt
set OUTDIR = /web/jsoc/htdocs/doc/data/hmi/harp/harp_nrt

# Must fetch low and high from gate state files. Assume the working directory is the harp-images gate directory.
set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

# Must round down to the nearest hour. I have no clue how you'd do this in csh, so I'm doing this in perl.
# Assume that at least the hour field is present.
set low = `perl -e 'my($wantlow) = "'$wantlow'"; if ($wantlow =~ /^\s*(\d\d\d\d)\.(\d+)\.(\d+)_(\d+)(.*)/) { my($pref) = sprintf("%4d", $1) . "\." . sprintf("%02d", $2) . "\." . sprintf("%02d", $3) . "_" . sprintf("%02d", $4); my($suff) = $5; my($tz) = ""; if ($suff =~ /^[^_]*_(\S+)/) {$tz = "_$1"; } print "$pref:00:00$tz"; }'`

set high = `perl -e 'my($wanthigh) = "'$wanthigh'"; if ($wanthigh =~ /^\s*(\d\d\d\d)\.(\d+)\.(\d+)_(\d+)(.*)/) { my($pref) = sprintf("%4d", $1) . "\." . sprintf("%02d", $2) . "\." . sprintf("%02d", $3) . "_" . sprintf("%02d", $4); my($suff) = $5; my($tz) = ""; if ($suff =~ /^[^_]*_(\S+)/) {$tz = "_$1"; } print "$pref:00:00$tz"; }'`

# Create the .png file(s)
$SCRTREE'/'$SCRIPT -f $MASKSERIES'['$low'-'$high'@1h]' $HARPSERIES $OUTDIR

# Create some auxiliary images for the latest .png file
set CMD = $SHOWINFO' -q key=T_REC '$HARPSERIES'[][$] | uniq'
set TREC = `$CMD`

# Identify the latest .png file
set PNG = $OUTDIR'/harp.'$TREC'.png'

# Fancify latest .png file
set TMP = $OUTDIR'/.latest_nrt.png'
set PNGLATEST = $OUTDIR'/latest_nrt.png'
cp $PNG $TMP
convert $TMP -fill white -gravity North -pointsize 36 -font Helvetica -annotate 0 'near real-time (nrt) data' $TMP
if ($?) then
    rm -f $TMP
else
    mv $TMP $PNGLATEST
endif

# Create negative color image for nrt data visualization
set TMP = $OUTDIR'/.latest.png'
set NEG = $OUTDIR'/latest.png'
cp $PNG $TMP
convert $TMP -negate $TMP
if ($?) then
    rm -f $TMP
else
    mv $TMP $NEG
endif

# Create thumbnail
set TMP = $OUTDIR'/.thumbnail.png'
set THUMB = $OUTDIR'/thumbnail.png'
convert -define png:size=1024x1024 $PNG -thumbnail 256x256 -unsharp 0x.5 $TMP
if ($?) then
    rm -f $TMP
else
    mv $TMP $THUMB
endif

# Delete all .png files older than 60 days                                                                         
find $OUTDIR'/'harp.*.png* -type f -atime +60 -exec rm -f {} \;
