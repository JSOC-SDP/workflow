#! /bin/csh -f
# Script to make hmi.limbfit
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test
set LIMB_PROGRAM = "${DRMS_BINS_INSTALL_DIR}"/lfwrp_tas
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info

set HERE = $cwd 

if ($?WORKFLOW_DATA) then
  set WFDIR = $WORKFLOW_DATA
else
  echo Need WORKFLOW_DATA variable to be set.
  exit 1
endif

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j.q
  set QSUB = /SGE/bin/lx24-amd64/qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

#set QSUB = $SGE_ROOT/bin/$SGE_ARCH

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set TMPDIR = /tmp28/jsocprod/lfwrp

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
echo "$LIMB_PROGRAM tmpdir=$TMPDIR/ logdir=$TMPDIR/logs/ bfsn=$WANTLOW efsn=$WANTHIGH dsout=hmi.limbfit_tas >>&$TEMPLOG" >>$TEMPCMD
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
