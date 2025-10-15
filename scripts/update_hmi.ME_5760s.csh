#! /bin/csh -f
# Script to make hmi.ME_5760s
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test
set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

if ( ! $?WORKFLOW_DIR ) then
    echo WORKFLOW_DIR environment variable is undefined, setting local variable to "${DRMS_SRC_INSTALL_DIR}"/workflow
    set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow
endif

set INDEX_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/index_convert
set MAKE_TICKET = "${WORKFLOW_DIR}"/maketicket.csh
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert
set VFISV = "${DRMS_BINS_INSTALL_DIR}"/vfisv

set QSUBFLAGS = "-v JSOC_r10"
# UGH
if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
    set MPIEXEC = /home/jsoc/bin/linux_avx/mpiexec
else
    if ( $JSOC_MACHINE == "linux_x86_64" ) then
      set QUE = p8.q,j8.q
      set QSUB = "qsub $QSUBFLAGS"
      set MPIEXEC = /home/jsoc/mpich2/bin/mpiexec
    else if ( $JSOC_MACHINE == "linux_avx" ) then
      set QUE = k.q
      set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
      set MPIEXEC = /home/jsoc/bin/linux_avx/mpiexec
    endif
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`


set timest = `echo $WANTLOW | cut -c9-13,15-16`
set OLOG = $HERE/runlog
set ELOG = $HERE/errlog
set TEMPCMD = $HERE/ME96$timest
echo 6 > $HERE/retstatus

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$OLOG" >>$TEMPCMD
echo "set echo >>&$OLOG" >>$TEMPCMD
#echo "setenv SGE_ROOT /SGE" >>$TEMPCMD
echo "setenv MPI_MAPPED_STACK_SIZE 100M" >> $TEMPCMD
echo "setenv MPI_MAPPED_HEAP_SIZE 100M" >> $TEMPCMD
echo "setenv KMP_STACKSIZE 16M" >> $TEMPCMD
echo "unlimit" >> $TEMPCMD
echo "limit core 0" >> $TEMPCMD
echo "setenv OMP_NUM_THREADS 4" >> $TEMPCMD

# Ugh
if ( $JSOC_MACHINE == "linux_x86_64" ) then
  echo "/home/jsoc/mpich2/bin/mpdboot --ncpus=8" >> $TEMPCMD 
endif
echo "sleep 10" >> $TEMPCMD

echo 'set MEstatus=0' >>&$TEMPCMD

# round times to a slot
set indexlow = `$INDEX_CONVERT ds=$product $key=$WANTLOW`
set indexhigh = `$INDEX_CONVERT ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `$INDEX_CONVERT ds=$product $key"_index"=$indexlow`
set wanthigh = `$INDEX_CONVERT ds=$product $key"_index"=$indexhigh`

foreach T ( `$SHOW_INFO 'hmi.S_5760s['$wantlow'-'$wanthigh']' -q key=t_rec` ) 
  echo "$MPIEXEC -n 4 $VFISV -f out=hmi.ME_5760s in=hmi.S_5760s\["$T"] -v chi2_stop=1e-15" >>$TEMPCMD
end

echo 'set MEstatus = $?' >>$TEMPCMD
echo 'if ($MEstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $MEnrtstatus >retstatus' >>&$TEMPCMD
echo "echo DONE >> $OLOG" >>$TEMPCMD
# execute qsub script

$QSUB -pe smp 4 -e $ELOG -o $OLOG -q $QUE $TEMPCMD

if (-e retstatus) then
  set retstatus = `cat $HERE/retstatus`
  if ( $retstatus == 0 ) then
    @ s = `$TIME_CONVERT time=$wanthigh`
    @ sB = $s + 360
    set BHigh = `$TIME_CONVERT s=$sB zone=TAI`
    set B_TICKET = `$MAKE_TICKET gate=hmi.B_5760s wantlow=$wantlow wanthigh=$BHigh action=5`
  endif
endif

exit $retstatus
