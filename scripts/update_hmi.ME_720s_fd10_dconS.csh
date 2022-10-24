#! /bin/csh -f
# Script to make hmi.ME_720s_fd10_dconS
#

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test

source /home/jsoc/.setJSOCenv

set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

set QUE = k.q
set QSUB = /SGE2/bin/lx-amd64/qsub

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set VFISV = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/vfisv
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
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

foreach T ( `$SHOW_INFO JSOC_DBUSER=production 'hmi.S_720s_dconS['$wantlow'-'$wanthigh']' -q key=t_rec` ) 
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
  set B_TICKET = `$WFCODE/maketicket.csh gate=hmi.B_720s_dconS wantlow=$wantlow wanthigh=$BHigh action=5`
endif

exit $retstatus

