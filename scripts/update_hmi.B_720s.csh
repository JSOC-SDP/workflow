#! /bin/csh -f
# Script to make hmi.ME_720s_fd10
#

# XXXXXXXXXX test
# set echo
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
  set QUE = a.q
  set QSUB = qsub2
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`


set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = HMIB
set qsubname = $timename$timestr

set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

set DIS = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/disambig_v3
set ARGS = "AMBNEQ=100 AMBTFCTR=0.98 OFFSET=50 AMBNPAD=200 AMBNTX=30 AMBNTY=30 AMBNAP=10 AMBSEED=4 errlog=$TEMPLOG" 

# make qsub scripts
#
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set HMIBstatus=6' >>&$TEMPCMD

echo "$DIS in=hmi.ME_720s_fd10\["$T"] out=hmi.B_720s $ARGS " >> $TEMPCMD
echo 'set HMIBstatus = $?' >>$TEMPCMD
echo 'if ($HMIBstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $HMIBstatus >retstatus' >>&$TEMPCMD

# execute qsub script
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
