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

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end


set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/show_info
#set Limbprogram = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/lfwrp_tas
set Limbprogram = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/lfwrp

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

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
echo "$Limbprogram tmpdir=/tmp22/jsocprod/lfwrp/ logdir=/tmp22/jsocprod/lfwrp/logs/ bfsn=$WANTLOW efsn=$WANTHIGH dsout=hmi.limbfit  >>&$TEMPLOG" >>$TEMPCMD
#echo "$Limbprogram tmpdir=/tmp22/jsocprod/lfwrp/ logdir=/tmp22/jsocprod/lfwrp/logs/ bfsn=$WANTLOW efsn=$WANTHIGH dsout=hmi.limbfit_tas >>&$TEMPLOG" >>$TEMPCMD
echo 'set retstatus = $?' >>$TEMPCMD
echo 'echo $retstatus >' "$HERE/retstatus" >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD
echo "rm -f /home/jsoc/pipeline/tasks/update_hmi.Limb_Fit/qsub_running" >>$TEMPCMD

# execute qsub script
touch $HERE/qsub_running
touch /home/jsoc/pipeline/tasks/update_hmi.Limb_Fit/qsub_running
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
qsub -sync yes -e $TEMPLOG -o $TEMPLOG -q j.q,p.q $TEMPCMD >> runlog


if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
echo $?
