#! /bin/csh -f
# Script to make hmi.ME_720s_fd10
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test
set MAKE_TICKET = "${DRMS_SRC_INSTALL_DIR}/workflow/maketicket.csh"
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert
set VFISV = "${DRMS_BINS_INSTALL_DIR}"/vfisv

set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

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

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`


#set indexlow = `index_convert ds=$product $key=$WANTLOW`
#set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
#@ indexhigh = $indexhigh - 1
#set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
#set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`

set wantlow = $WANTLOW
set wanthigh = $WANTHIGH

set timest = `echo $WANTLOW | cut -c9-13,15-16`
set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/VFV$timest
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
# Ugh
if ( $JSOC_MACHINE == "linux_x86_64" ) then
  echo "/home/jsoc/mpich2/bin/mpdboot --ncpus=8" >> $TEMPCMD 
endif
echo "sleep 10" >> $TEMPCMD

echo 'set VFnrtstatus=0' >>&$TEMPCMD

echo "/usr/bin/Mail -s 'normal ME script' jeneen@sun.stanford.edu"  >>$TEMPCMD

foreach T ( `$SHOW_INFO JSOC_DBUSER=production 'hmi.S_720s['$wantlow'-'$wanthigh']' -q key=t_rec` ) 
  echo "$MPIEXEC -n 8 $VFISV -f -L out=hmi.ME_720s_fd10 in=hmi.S_720s\["$T"] in5=hmi.M_720s\["$T"] -v chi2_stop=1e-15" >>$TEMPCMD
end

echo 'set VFnrtstatus = $?' >>$TEMPCMD
echo 'if ($VFnrtstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $VFnrtstatus >retstatus' >>&$TEMPCMD
echo "echo DONE >> $TEMPLOG" >>$TEMPCMD
# execute qsub script

$QSUB -pe smp 8 -sync yes -l h_rt=36:00:00 -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
if ( $retstatus == 0 ) then
  @ s = `$TIME_CONVERT time=$wanthigh`
  @ sB = $s + 360
  set BHigh = `$TIME_CONVERT s=$sB zone=TAI`
  set B_TICKET = `$MAKE_TICKET gate=hmi.B_720s wantlow=$wantlow wanthigh=$BHigh action=5`
endif
exit $retstatus
