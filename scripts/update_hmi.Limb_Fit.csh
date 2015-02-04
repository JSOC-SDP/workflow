#! /bin/csh -f
# Script to make hmi.limbfit
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
#  set QSUB = /SGE/bin/lx24-amd64/qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
#  set QSUB = /SGE/bin/lx24-amd64/qsub2
endif

set QSUB = $SGE_ROOT/bin/$SGE_ARCH

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end


set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set Limbprogram = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/lfwrp_tas
#set Limbprogram = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/lfwrp

set TMPDIR = /surge40/jsocprod/lfwrp

set product = `/bin/cat $WFDIR/gates/$GATE/product`
set key = `/bin/cat $WFDIR/gates/$GATE/key`

set qsubname = LIMB$WANTLOW
set TEMPLOG = $HERE/runlog
set babble = $HERE/babble
set TEMPCMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

set retstatus=0

#make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
#echo "$Limbprogram tmpdir=/tmp29/jsocprod/lfwrp/ logdir=/tmp29/jsocprod/lfwrp/logs/ bfsn=$WANTLOW efsn=$WANTHIGH dsout=hmi.limbfit  >>&$TEMPLOG" >>$TEMPCMD
echo "$Limbprogram tmpdir=$TMPDIR/ logdir=$TMPDIR/logs/ bfsn=$WANTLOW efsn=$WANTHIGH dsout=hmi.limbfit_tas >>&$TEMPLOG" >>$TEMPCMD
echo 'set retstatus = $?' >>$TEMPCMD
echo 'echo $retstatus >' "$HERE/retstatus" >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD
echo "rm -f /home/jsoc/pipeline/tasks/update_hmi.Limb_Fit/qsub_running" >>$TEMPCMD

# execute qsub script
/bin/touch $HERE/qsub_running
set TEMPLOG = `echo $TEMPLOG | /bin/sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog


if (-e retstatus) set retstatus = `/bin/cat $HERE/retstatus`
exit $retstatus
echo $?
