#! /bin/csh -f
# Script to make HMI MrMap_latlon_720s - Mag Acrive Region Mask 720s
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test

set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = k.q
set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set MAPROJ = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/maprojlonat02deg
set MAPARGS = "cols=9000 rows=9000 scale=0.02 map=carree -R clat=0.0"

set wantlow = $WANTLOW
set wanthigh = $WANTHIGH

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = MrMap
set qsubname = $timename$timestr

set LOG = $HERE/runlog
set CMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

# make qsub script
echo "#! /bin/csh -f " >$CMD
echo "cd $HERE" >>$CMD
echo "hostname >>&$LOG" >>$CMD
echo "set echo >>&$LOG" >>$CMD
echo 'set retstatus=6' >>&$CMD

foreach T ( `$SHOW_INFO -q hmi.M_720s'['$wantlow'-'$wanthigh']' key=t_rec` )
  echo "$MAPROJ -v in=hmi.M_720s_nrt'['$T']' out=hmi.Mrmap_latlon_720s_nrt $MAPARGS" >> $CMD
end
echo 'set retstatus = $?' >>$CMD
echo 'if ($retstatus) goto DONE' >>&$CMD
echo 'DONE:' >>$CMD
echo 'echo $retstatus >retstatus' >>&$CMD

# execute qsub script
set LOG = `echo $LOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
