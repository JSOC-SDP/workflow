#! /bin/csh -f 
# This script creates the HARP 720s nrt web images. Each image is a superposition of all HARP images that have been observed
# on a given day.

set SRCTREE = /home/jsoc/cvs/Development/JSOC
set SHOWINFO = $SRCTREE'/'bin/linux_x86_64/show_info
set SCRIPT = proj/mag/harp/scripts/track_hmi_harp_movie_driver.sh
set CONVERT = /usr/bin/convert
set MASKSERIES = hmi.Marmask_720s_nrt
set HARPSERIES = hmi.Mharp_720s_nrt
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/time_convert

set OUTDIR = /surge40/jsocprod/HARPS/nrt/images

set HERE = $cwd

# Must fetch low and high from the ticket used to start the data update
foreach ATTR (WANTLOW WANTHIGH)
  set ATTRTXT = `grep $ATTR ticket`
  set $ATTRTXT
end

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`

set qsubscr = NHI$timestr

echo wantlow is $wantlow >> $HERE/runlog
echo wanthigh is $wanthigh >> $HERE/runlog
echo qsubscr is $qsubscr >> $HERE/runlog

# Initialize the retstatus state file to what I guess is a bad value
echo 6 > $HERE/retstatus

# Must round down to the nearest hour. I have no clue how you'd do this in csh, so I'm doing this in perl.
# Assume that at least the hour field is present.
set low = `$TIME_CONVERT time=$wantlow zone=UTC o=cal | cut -c1-13`:00_TAI

set high = `$TIME_CONVERT time=$wanthigh zone=UTC o=cal | cut -c1-13`:00_TAI

set CMDFILE = $HERE/$qsubscr
set LOG = $HERE/runlog
rm -f $CMDFILE
rm -f $HERE/runlog

# Create the qsub script
echo "#! /bin/csh -f " >> $CMDFILE
echo "cd $HERE" >> $CMDFILE
echo "hostname >>&$LOG" >>$CMDFILE

# Run Turmon's matlab stuff
set echo
echo "$SRCTREE/$SCRIPT -fE $MASKSERIES'['"$low-$high@1h"']' $HARPSERIES $OUTDIR >>& $HERE/runlog" >> $CMDFILE

# Now use Turmon's stuff to make other image files

# Create some auxiliary images for the latest .png file

# Identify the latest .png file
echo 'set lastPNG = `ls -1 '$OUTDIR'/harp.*.png | tail -1`' >> $CMDFILE
echo 'echo $lastPNG >>& '$HERE'/runlog' >> $CMDFILE

# Fancify latest.png file
set TMP = $OUTDIR/.latest_nrt.png
set PNGLATEST = $OUTDIR/latest_nrt.png
echo 'cp $lastPNG '$TMP >> $CMDFILE
echo "$CONVERT $TMP -fill white -gravity North -pointsize 36 -font Helvetica -annotate 0 'near real-time (nrt) data' $TMP" >> $CMDFILE
echo "mv $TMP $PNGLATEST" >> $CMDFILE

# Create negative color image for nrt data visualization
set TMP = $OUTDIR/.latest.png >> $CMDFILE
set NEG = $OUTDIR/latest_negative.png >> $CMDFILE
echo 'cp $lastPNG '$TMP >> $CMDFILE
echo "$CONVERT $TMP -negate $TMP" >> $CMDFILE
echo "mv $TMP $NEG" >> $CMDFILE

# Create thumbnail
set TMP = $OUTDIR/.thumbnail.png >> $CMDFILE
set THUMB = $OUTDIR/thumbnail.png >> $CMDFILE
echo 'cp $lastPNG '$TMP >> $CMDFILE
echo "$CONVERT -define png:size=1024x1024 $TMP -thumbnail 256x256 -unsharp 0x.5 $TMP" >> $CMDFILE
echo "mv $TMP $THUMB" >> $CMDFILE

# get latest Harp image time
/home/jeneen/latestHMI/getHarpTime.csh

# Delete all .png files older than 60 days 
find $OUTDIR/harp.*.png* -type f -mtime +60 -print0 | xargs -0 rm -f

# Set the real return status
echo 'set retstatus = $?' >> $CMDFILE
echo 'echo $retstatus > ' "$HERE/retstatus" >> $CMDFILE

# Execute the qsub script
touch $HERE/qsub_running
#set log = `echo $HERE/runlog | sed "s/^\/auto//"`
qsub -e $LOG -o $LOG -sync yes -q j.q $CMDFILE

set retstatus = `cat $HERE/retstatus`
exit $retstatus
