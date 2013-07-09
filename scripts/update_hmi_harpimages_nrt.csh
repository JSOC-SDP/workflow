#! /bin/csh -f 
# This script creates the HARP 720s nrt web images. Each image is a superposition of all HARP images that have been observed
# on a given day.

set SCRTREE = /home/jsoc/cvs/Development/JSOC
set SHOWINFO = $SRCTREE'/'bin/linux_x86_64/show_info
set SCRIPT = proj/mag/harp/scripts/track_hmi_harp_movie_driver.sh
set MASKSERIES = hmi.Marmask_720s_nrt
set HARPSERIES = hmi.Mharp_720_nrt
set OUTDIR = /web/jsoc/htdocs/doc/data/hmi/harp/harp_nrt

# Must fetch low and high from the ticket used to start the data update
foreach ATTR (WANTLOW WANTHIGH)
    set ATTRTXT = `grep $ATTR ticket`
    set $ATTRTXT
end

set wantlow = $WANTLOW
set wanthigh = $WANTHIGH
set timestr = `perl -e 'my($wantlow) = "'$wantlow'"; if ($wantlow =~ /^\s*\d\d\d\d\.\d\d\.(\d\d)_(\d\d):(\d\d)/) { print "$1_$2$3"; }'` 
set qsubscr = ABA$timestr

echo wantlow is $wantlow >> $HERE/runlog
echo wanthigh is $wanthigh >> $HERE/runlog
echo qsubscr is $qsubscr >> $HERE/runlog

# Initialize the retstatus state file to what I guess is a bad value
echo 6 > $HERE/retstatus

# Must round down to the nearest hour. I have no clue how you'd do this in csh, so I'm doing this in perl.
# Assume that at least the hour field is present.
set low = `perl -e 'my($wantlow) = "'$wantlow'"; if ($wantlow =~ /^\s*(\d\d\d\d)\.(\d+)\.(\d+)_(\d+)(.*)/) { my($pref) = sprintf("%4d", $1) . "\." . sprintf("%02d", $2) . "\." . sprintf("%02d", $3) . "_" . sprintf("%02d", $4); my($suff) = $5; my($tz) = ""; if ($suff =~ /^[^_]*_(\S+)/) {$tz = "_$1"; } print "$pref:00:00$tz"; }'`

set high = `perl -e 'my($wanthigh) = "'$wanthigh'"; if ($wanthigh =~ /^\s*(\d\d\d\d)\.(\d+)\.(\d+)_(\d+)(.*)/) { my($pref) = sprintf("%4d", $1) . "\." . sprintf("%02d", $2) . "\." . sprintf("%02d", $3) . "_" . sprintf("%02d", $4); my($suff) = $5; my($tz) = ""; if ($suff =~ /^[^_]*_(\S+)/) {$tz = "_$1"; } print "$pref:00:00$tz"; }'`

set cmd = $SCRTREE'/'$SCRIPT -f $MASKSERIES'['$low'-'$high'@1h]' $HARPSERIES $OUTDIR

set CMDFILE = $HERE/qsubscr

# Create the qsub script
echo "#! /bin/csh -f " >> $CMDFILE
echo "cd $HERE" >> $CMDFILE
echo -n "HOST is >> $HERE/runlog" >> $CMDFILE
echo "hostname >>& $HERE/runlog" >> $CMDFILE

# Run Turmon's matlab stuff
echo "$cmd >>& $HERE/runlog" >> $CMDFILE

# Now use Turmon's stuff to make other image files

# Create some auxiliary images for the latest .png file
echo "set CMD = show_info -q key=T_REC $HARPSERIES"\[\][\$\]" | uniq" >> $CMDFILE
echo \`$CMD\` >> $CMDFILE

# Identify the latest .png file
echo "PNG = $OUTDIR/harp.$TREC.png" >> $CMDFILE

# Fancify latest .png file
echo "set TMP = $OUTDIR/.latest_nrt.png" >> $CMDFILE
echo "set PNGLATEST = $OUTDIR/latest_nrt.png" >> $CMDFILE
echo "cp $PNG $TMP" >> $CMDFILE
echo "convert $TMP -fill white -gravity North -pointsize 36 -font Helvetica -annotate 0 'near real-time (nrt) data' $TMP" >> $CMDFILE
echo "if ("\$"?) then" >> $CMDFILE
echo "rm -f $TMP" >> $CMDFILE
echo "else" >> $CMDFILE
echo "mv $TMP $PNGLATEST" >> $CMDFILE
echo "endif" >> $CMDFILE

# Create negative color image for nrt data visualization
echo "set TMP = $OUTDIR/.latest.png" >> $CMDFILE
echo "set NEG = $OUTDIR/latest.png" >> $CMDFILE
echo "cp $PNG $TMP" >> $CMDFILE
echo "convert $TMP -negate $TMP" >> $CMDFILE
echo "if ("\$"?) then" >> $CMDFILE
echo "rm -f $TMP" >> $CMDFILE
echo "else" >> $CMDFILE
echo "mv $TMP $NEG" >> $CMDFILE
echo "endif" >> $CMDFILE

# Create thumbnail
echo "set TMP = $OUTDIR/.thumbnail.png" >> $CMDFILE
echo "set THUMB = $OUTDIR/thumbnail.png" >> $CMDFILE
echo "convert -define png:size=1024x1024 $PNG -thumbnail 256x256 -unsharp 0x.5 $TMP" >> $CMDFILE
echo "if ("\$"?) then" >> $CMDFILE
echo "rm -f $TMP" >> $CMDFILE
echo "else" >> $CMDFILE
echo "mv $TMP $THUMB" >> $CMDFILE
echo "endif" >> $CMDFILE

# Delete all .png files older than 60 days
echo "find $OUTDIR/harp.*.png* -type f -atime +60 -exec rm -f {} \\;" >> $CMDFILE

# Set the real return status
echo 'set retstatus = $?' >> $CMDFILE
echo 'echo $retstatus > ' "$HERE/retstatus" >> $CMDFILE

# Execute the qsub script
touch $HERE/qsub_running
set log = `echo $HERE/runlog | sed "s/^\/auto//"`
qsub -e $log -o $log -sync yes -q j.q $CMDFILE

set retstatus = `cat $HERE/retstatus`
exit $retstatus
