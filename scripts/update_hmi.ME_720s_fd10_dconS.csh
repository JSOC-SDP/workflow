#! /bin/csh -f
# Script to make hmi.ME_720s_fd10_dconS
#

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test
set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set MAKE_TICKET = $WORKFLOW_DIR/maketicket.csh
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert
set VFISV = "${DRMS_BINS_INSTALL_DIR}"/vfisv

source /home/jsoc/.setJSOCenv

if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    set QSUB = /SGE2/bin/lx-amd64/qsub
else
    set QUE = k.q
    set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

# UGH
set MPIEXEC = /home/jsoc/bin/linux_avx/mpiexec

set wantlow = $WANTLOW
set wanthigh = $WANTHIGH

set timest = `echo $WANTLOW | cut -c9-13,15-16`
set LOG = $HERE/runlog
set CMD = $HERE/DCV$timest
echo 6 > $HERE/retstatus

# make qsub script
echo "#! /bin/csh -f " >$CMD
echo "cd $HERE" >>$CMD
echo "hostname >>&$LOG" >>$CMD
echo "set echo >>&$LOG" >>$CMD
echo "setenv OMP_NUM_THREADS 4" >>$CMD
echo "setenv MPI_MAPPED_STACK_SIZE 100M" >> $CMD
echo "setenv MPI_MAPPED_HEAP_SIZE 100M" >> $CMD
echo "setenv KMP_STACKSIZE 16M" >> $CMD
echo "unlimit" >> $CMD
echo "limit core 0" >> $CMD

echo 'set VFnrtstatus=6' >>&$CMD

foreach T ( `$SHOW_INFO 'hmi.S_720s_dconS['$wantlow'-'$wanthigh']' -q key=t_rec` ) 
  echo "$MPIEXEC -n 4 $VFISV -f out=hmi.ME_720s_fd10_dconS in=hmi.S_720s_dconS\["$T"] in5=hmi.M_720s_dconS\["$T"] -v chi2_stop=1e-15" >>$CMD
end

echo 'set VFnrtstatus = $?' >>$CMD
echo 'if ($VFnrtstatus) goto DONE' >>&$CMD
echo 'DONE:' >>$CMD
echo 'echo $VFnrtstatus >retstatus' >>&$CMD
echo "echo DONE >> $LOG" >>$CMD

# execute qsub script

$QSUB -sync yes -pe smp 4 -e $LOG -o $LOG -q $QUE $CMD

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
if ( $retstatus == 0 ) then
  @ s = `$TIME_CONVERT time=$wanthigh`
  @ sB = $s + 360
  set BHigh = `$TIME_CONVERT s=$sB zone=TAI`
  set B_TICKET = `$MAKE_TICKET gate=hmi.B_720s_dconS wantlow=$wantlow wanthigh=$BHigh action=5`
endif

exit $retstatus
