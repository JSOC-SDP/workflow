#! /bin/csh -f
# Script to make hmi.ME_5760s
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test
set INDEX_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/index_convert
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert
set VFISV = "${DRMS_BINS_INSTALL_DIR}"/vfisv

source /home/jsoc/.setJSOCenv

set HERE = $cwd 

if ($?WORKFLOW_DATA) then
  set WFDIR = $WORKFLOW_DATA
else
  echo Need WORKFLOW_DATA variable to be set.
  exit 1
endif

# UGH
if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = p8.q,j8.q
  set QSUB = qsub
  set MPIEXEC = /home/jsoc/mpich2/bin/mpiexec
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = k.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
  set MPIEXEC = /home/jsoc/bin/linux_avx/mpiexec
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`


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

foreach T ( `$SHOW_INFO JSOC_DBUSER=production 'hmi.S_5760s['$wantlow'-'$wanthigh']' -q key=t_rec` ) 
  echo "$MPIEXEC -n 4 $VFISV -f out=hmi.ME_5760s in=hmi.S_5760s\["$T"] -v chi2_stop=1e-15" >>$TEMPCMD
end

echo 'set MEstatus = $?' >>$TEMPCMD
echo 'if ($MEstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $MEnrtstatus >retstatus' >>&$TEMPCMD
echo "echo DONE >> $OLOG" >>$TEMPCMD
# execute qsub script

$QSUB -pe smp 4 -e $ELOG -o $OLOG -q $QUE $TEMPCMD

if (-e retstatus) set retstatus = `cat $HERE/retstatus`

exit $retstatus
