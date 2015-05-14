#! /bin/csh -f 
# This script creates the HARP 720s definitive web images. Each image is a superposition of all HARP images that have been observed
# on a given day.

#set echo

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

set HERE = $cwd
set SRCTREE = /home/jsoc/cvs/Development/JSOC
set SCRIPT = proj/mag/harp/scripts/track_hmi_harp_movie_driver.sh
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set MASKSERIES = hmi.Marmask_720s
set HARPSERIES = hmi.Mharp_720s
set OUTDIR = /surge40/jsocprod/HARPS/definitive/tmp
if ( ! -e $OUTDIR ) then
  mkdir -p $OUTDIR
endif


# Must fetch low and high from the ticket used to start the data update
foreach ATTR (WANTLOW WANTHIGH)
    set ATTRTXT = `grep $ATTR ticket`
    set $ATTRTXT
end

set wantlow = $WANTLOW
set wanthigh = $WANTHIGH
#set wantlow=2011.03.26
#set wanthigh=2011.03.26_03

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`

set qsubscr = HI$timestr

# Initialize the retstatus state file to what I guess is a bad value
echo 6 > $HERE/retstatus

# Must round down to the nearest hour. I have no clue how you'd do this in csh, so I'm doing this in perl.
# Assume that at least the hour field is present.
set low = `perl -e 'my($wantlow) = "'$wantlow'"; if ($wantlow =~ /^\s*(\d\d\d\d)\.(\d+)\.(\d+)(.*)/) { my($datestr) = $1 . "\." . $2 . "\." . $3; my($hrstr) = "_00"; my($suff) = $4; my($tz) = ""; if ($suff =~ /^_(\d+)(.*)$/) { $hrstr = "_$1"; $suff = $2; if ($suff =~ /^[^_]*_(\S+)/) {$tz = "_$1"; } } elsif ($suff =~ /^_(.*)/) { $tz = "_$1"; } print "$datestr$hrstr:00:00$tz"; }'`

set high = `perl -e 'my($wanthigh) = "'$wanthigh'"; if ($wanthigh =~ /^\s*(\d\d\d\d)\.(\d+)\.(\d+)(.*)/) { my($datestr) = $1 . "\." . $2 . "\." . $3; my($hrstr) = "_00"; my($suff) = $4; my($tz) = ""; if ($suff =~ /^_(\d+)(.*)$/) { $hrstr = "_$1"; $suff = $2; if ($suff =~ /^[^_]*_(\S+)/) {$tz = "_$1"; } } elsif ($suff =~ /^_(.*)/) { $tz = "_$1"; } print "$datestr$hrstr:00:00$tz"; }'`

set CMDFILE = $HERE/$qsubscr
set log = $HERE/runlog

# Create the qsub script
echo "#! /bin/csh -f " >> $CMDFILE
echo "cd $HERE" >> $CMDFILE
#echo "HOST is $HOST >>& $log" >> $CMDFILE
echo "hostname >>&$log" >>$CMDFILE

echo "$SRCTREE/$SCRIPT -fE $MASKSERIES'['"$low-$high@1h"']' $HARPSERIES $OUTDIR >>& $log" >> $CMDFILE
foreach trec (`$SHOW_INFO $MASKSERIES'['"$low-$high@1h"']' -q key=T_REC` )
  echo $trec
  set file = $OUTDIR/harp.$trec.png
  @ year = `echo $trec | awk -F\. '{print $1}'`
  set mo = `echo $trec | awk -F\. '{print $2}'`
  set dy = `echo $trec | awk -F\. '{print $3}' | awk -F\_ '{print $1}'`
  mkdir -p /surge40/jsocprod/HARPS/definitive/images/$year/$mo/$dy
  echo "if ( -e $file ) then" >>$CMDFILE
  echo "  mv $file /surge40/jsocprod/HARPS/definitive/images/$year/$mo/$dy" >> $CMDFILE
  echo "endif" >> $CMDFILE
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
