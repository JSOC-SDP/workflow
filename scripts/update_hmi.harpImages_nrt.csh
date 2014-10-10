#! /bin/csh -f 
# This script creates the HARP 720s definitive web images. Each image is a superposition of all HARP images that have been observed
# on a given day.

#set echo

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
  set QSUB = qsub2
endif

set HERE = $cwd
set SRCTREE = /home/jsoc/cvs/Development/JSOC
set SCRIPT = proj/mag/harp/scripts/track_hmi_harp_movie_driver.sh
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
set MASKSERIES = hmi.Marmask_720s_nrt
set HARPSERIES = hmi.Mharp_720s_nrt
set OUTDIR = /surge40/jsocprod/HARPS/nrt/images
set CONVERT = /usr/bin/convert
if ( ! -e $OUTDIR ) then
  mkdir -p $OUTDIR
endif

foreach ATTR (GATE WANTLOW WANTHIGH)
  set ATTRTXT = `grep $ATTR ticket`
  set $ATTRTXT
end

#set WANTLOW = $argv[1]
#set WANTHIGH = $argv[2]

@ low_s = `$TIME_CONVERT time=$WANTLOW`
@ high_s = `$TIME_CONVERT time=$WANTHIGH`
set first_hour = `echo $WANTLOW | awk -F\: '{print $1}'`_TAI
@ first_hour_s = `$TIME_CONVERT time=$first_hour`
@ next_hour_s = $first_hour_s + 3600

if ( ($low_s > $first_hour_s) && ($high_s < $next_hour_s) ) then
  # nothing to do
  exit 0
endif

if ( $low_s == $first_hour_s ) then
  set low = `echo $WANTLOW | awk -F\: '{print $1}'`
else
  set low = `$TIME_CONVERT s=$next_hour_s zone=TAI o=cal | awk -F\: '{print $1}'`
endif

set high = `echo $WANTHIGH | awk -F\: '{print $1}'`

set HERE = $cwd
set timestr = `echo $WANTLOW  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set CMDFILE = $HERE/HI$timestr
set log = $HERE/runlog
echo 6 > $HERE/retstatus

# Create the qsub script
echo "#! /bin/csh -f " >> $CMDFILE
echo "cd $HERE" >> $CMDFILE
echo "hostname >>&$log" >>$CMDFILE

echo "$SRCTREE/$SCRIPT -fE $MASKSERIES'['"$low-$high@1h"']' $HARPSERIES $OUTDIR >>& $log" >> $CMDFILE
foreach trec (`$SHOW_INFO $MASKSERIES'['"$low-$high@1h"']' -q key=T_REC` )
  echo $trec
  set file = $OUTDIR/harp.$trec.png
  echo "if ( -e $file ) then" >>$CMDFILE
  echo "  mv $file /surge40/jsocprod/HARPS/nrt/images" >> $CMDFILE
  echo "endif" >> $CMDFILE
end

# Identify the latest .png file
echo 'set lastPNG = `ls -1 '$OUTDIR'/harp.*.png | tail -1`' >> $CMDFILE
echo 'echo '$lastPNG' >>& '$HERE'/runlog' >> $CMDFILE

# Fancify latest.png file
set TMP = $OUTDIR/.latest_nrt.png
set PNGLATEST = $OUTDIR/latest_nrt.png
echo "cp $lastPNG $TMP" >> $CMDFILE
echo "$CONVERT $TMP -fill white -gravity North -pointsize 36 -font Helvetica -annotate 0 'near real-time (nrt) data' $TMP" >> $CMDFILE
echo "mv $TMP $PNGLATEST" >> $CMDFILE

# Create negative color image for nrt data visualization
set TMP = $OUTDIR/.latest.png >> $CMDFILE
set NEG = $OUTDIR/latest_negative.png >> $CMDFILE
echo "cp $lastPNG $TMP" >> $CMDFILE
echo "$CONVERT $TMP -negate $TMP" >> $CMDFILE
echo "mv $TMP $NEG" >> $CMDFILE

# Create thumbnail
set TMP = $OUTDIR/.thumbnail.png >> $CMDFILE
set THUMB = $OUTDIR/thumbnail.png >> $CMDFILE
echo "cp $lastPNG $TMP" >> $CMDFILE
echo "$CONVERT -define png:size=1024x1024 $TMP -thumbnail 256x256 -unsharp 0x.5 $TMP" >> $CMDFILE
echo "mv $TMP $THUMB" >> $CMDFILE
echo "/home/jeneen/latestHMI/getHarpTime.csh" >> $CMDFILE

# Delete all .png files older than 60 days
foreach oldFile ( `find $OUTDIR/harp.*.png* -type f -atime +30` )
  rm $oldFile
end

# Set the real return status
echo 'set retstatus = $?' >> $CMDFILE
echo 'echo $retstatus > ' "$HERE/retstatus" >> $CMDFILE

# Execute the qsub script
touch $HERE/qsub_running
set log = `echo $log | sed "s/^\/auto//"`

$QSUB -e $log -o $log -sync yes -q $QUE $CMDFILE 

set retstatus = `cat $HERE/retstatus`
exit $retstatus
