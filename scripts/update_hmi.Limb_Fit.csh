#! /bin/csh -f
# Script to make hmi.limbfit
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test
set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set LIMB_PROGRAM = "${DRMS_BINS_INSTALL_DIR}"/lfwrp_tas
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info


set QSUBFLAGS = "-v JSOC_r10"
if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
else
    if ( $JSOC_MACHINE == "linux_x86_64" ) then
      set QUE = j.q
      set QSUB = "/SGE/bin/lx24-amd64/qsub $QSUBFLAGS"
    else if ( $JSOC_MACHINE == "linux_avx" ) then
      set QUE = a.q
      set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
    endif
endif

if ( $?WORKFLOW_TEST ) then
    set namespace = "hmi_test"
    set TMPDIR = /tmp30/jsoctest/lfwrp
else
    set namespace = "hmi"
    set TMPDIR = /tmp28/jsocprod/lfwrp
endif

#set QSUB = $SGE_ROOT/bin/$SGE_ARCH

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `/bin/cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `/bin/cat $WORKFLOW_DATA/gates/$GATE/key`

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
echo "$LIMB_PROGRAM tmpdir=$TMPDIR/ logdir=$TMPDIR/logs/ bfsn=$WANTLOW efsn=$WANTHIGH dsout=$namespace.limbfit_tas >>&$TEMPLOG" >>$TEMPCMD
echo 'set retstatus = $?' >>$TEMPCMD
echo 'echo $retstatus >' "$HERE/retstatus" >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD
echo "rm -f $WORKFLOW_DATA/tasks/update_hmi.Limb_Fit/qsub_running" >>$TEMPCMD

# execute qsub script
/bin/touch $HERE/qsub_running
set TEMPLOG = `echo $TEMPLOG | /bin/sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog


if (-e retstatus) set retstatus = `/bin/cat $HERE/retstatus`
exit $retstatus
echo $?
