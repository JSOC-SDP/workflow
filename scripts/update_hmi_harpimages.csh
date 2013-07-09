#! /bin/csh -f 
# This script creates the HARP 720s definitive web images. Each image is a superposition of all HARP images that have been observed
# on a given day.

set HERE = $cwd
set SCRTREE = /home/jsoc/cvs/Development/JSOC
set SCRIPT = proj/mag/harp/scripts/track_hmi_harp_movie_driver.sh
set MASKSERIES = hmi.Marmask_720s
set HARPSERIES = hmi.Mharp_720
set OUTDIR = /web/jsoc/htdocs/doc/data/hmi/harp/harp_definitive

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

# The guts of this exercise
echo "$cmd >>& $HERE/runlog" >> $CMDFILE

# Set the real return status
echo 'set retstatus = $?' >> $CMDFILE
echo 'echo $retstatus > ' "$HERE/retstatus" >> $CMDFILE

# Execute the qsub script
touch $HERE/qsub_running
set log = `echo $HERE/runlog | sed "s/^\/auto//"`
qsub -e $log -o $log -sync yes -q j.q $CMDFILE

set retstatus = `cat $HERE/retstatus`
exit $retstatus
