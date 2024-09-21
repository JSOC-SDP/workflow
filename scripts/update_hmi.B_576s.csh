#! /bin/csh -f
# Script to make hmi.B_5760s
#

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test

set HERE = $cwd

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set DISAMBIG = "${DRMS_BINS_INSTALL_DIR}"/disambig_v3

set QSUBFLAGS = "-v JSOC_r10"
if ( $?WORKFLOW_TEST ) then
    set namespace = "hmi_test"
    set QUE = k.q
    set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
else
    set namespace = "hmi"
    if ( $JSOC_MACHINE == "linux_x86_64" ) then
      set QUE = j.q
      set QSUB = "qsub $QSUBFLAGS"
    else if ( $JSOC_MACHINE == "linux_avx" ) then
      set QUE = k.q
      set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
    endif
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = B96
set qsubname = $timename$timestr

set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

set ARGS = "-L AMBGMTRY=0 AMBNEQ=100 AMBTFCTR=0.98 OFFSET=30 AMBNPAD=200 AMBNTX=30 AMBNTY=30 AMBNAP=10 AMBSEED=4"

# make qsub scripts
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set HMIBstatus=6' >>&$TEMPCMD

foreach T ( `$SHOW_INFO $namespace.ME_5760s'['$WANTLOW'-'$WANTHIGH']' -q key=T_REC` )
  echo "$DISAMBIG in=$namespace.ME_5760s'['$T']' out=$namespace.B_5760s $ARGS " >> $TEMPCMD
end

echo 'set HMIBstatus = $?' >>$TEMPCMD
echo 'if ($HMIBstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $HMIBstatus >retstatus' >>&$TEMPCMD

# execute qsub script
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`

exit $retstatus
