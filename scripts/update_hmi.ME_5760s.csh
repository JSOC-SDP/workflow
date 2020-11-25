#! /bin/csh -f
# Script to make hmi.ME_5760s
#

# XXXXXXXXXX test
 set echo
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

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = p8.q,j8.q
  set QSUB = qsub
  set MPIEXEC = /home/jsoc/mpich2/bin/mpiexec
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a8.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
  set MPIEXEC = /home/jsoc/bin/linux_avx/mpiexec
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set VFISV = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/vfisv
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert

set timest = `echo $WANTLOW | cut -c9-13,15-16`
set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/ME96$timest
echo 6 > $HERE/retstatus

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
#echo "setenv SGE_ROOT /SGE" >>$TEMPCMD
echo "setenv MPI_MAPPED_STACK_SIZE 100M" >> $TEMPCMD
echo "setenv MPI_MAPPED_HEAP_SIZE 100M" >> $TEMPCMD
echo "setenv KMP_STACKSIZE 16M" >> $TEMPCMD
echo "unlimit" >> $TEMPCMD
echo "limit core 0" >> $TEMPCMD
if ( $JSOC_MACHINE == "linux_x86_64" ) then
  echo "/home/jsoc/mpich2/bin/mpdboot --ncpus=8" >> $TEMPCMD 
endif
echo "sleep 10" >> $TEMPCMD

echo 'set MEstatus=0' >>&$TEMPCMD

# round times to a slot
set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`

foreach T ( `$SHOW_INFO JSOC_DBUSER=production 'hmi.S_5760s['$wantlow'-'$wanthigh']' -q key=t_rec` ) 
  echo "$MPIEXEC -n 8 $VFISV -f out=hmi.ME_5760s in=hmi.S_5760s\["$T"] -v chi2_stop=1e-15" >>$TEMPCMD
end

echo 'set MEstatus = $?' >>$TEMPCMD
echo 'if ($MEstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $MEnrtstatus >retstatus' >>&$TEMPCMD
echo "echo DONE >> $TEMPLOG" >>$TEMPCMD
# execute qsub script

$QSUB -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
#if ( $retstatus == 0 ) then
#  @ s = `$TIME_CONVERT time=$wanthigh`
#  @ sB = $s + 360
#  set BHigh = `$TIME_CONVERT s=$sB zone=TAI`
#  set B_TICKET = `$WFCODE/maketicket.csh gate=hmi.B_5760s wantlow=$wantlow wanthigh=$BHigh action=5`
#endif
exit $retstatus

