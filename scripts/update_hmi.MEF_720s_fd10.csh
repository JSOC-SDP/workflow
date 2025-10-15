#! /bin/csh -f
# Script to make hmi.MEF_720s_fd10
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

set GAPFILL = "${DRMS_BINS_INSTALL_DIR}"/set_gaps_missing
set INDEX_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/index_convert
set MAKE_TICKET = "${WORKFLOW_DIR}"/maketicket.csh
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert
set VFISV2COMP = "${DRMS_BINS_INSTALL_DIR}"/vfisv_2comp

set QSUBFLAGS = "-v JSOC_r10"
if ( $?WORKFLOW_TEST ) then
    set namespace = "hmi_test"
    set QUE = k.q
    set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
    set MPIEXEC = /home/jsoc/bin/linux_avx/mpiexec
else
    set namespace = "hmi"
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
set wantlow = $WANTLOW

# This is to avoid duplicate records caused by the tickets being broken down into smaller
# tickets than the parent series (hmi.S_720s).  Temporary until I can find a better solution.
set possible_dup = "`echo $WANTHIGH | cut -c12-13,15-16`"
if ( ($possible_dup =~ "0224") || ($possible_dup =~ "0824") || ($possible_dup =~ "1424") || ($possible_dup =~ "2024") ) then
  @ indexhigh = `$INDEX_CONVERT ds=$product $key=$WANTHIGH` - 1
  set wanthigh = `$INDEX_CONVERT ds=$product $key"_index"=$indexhigh`
else
  set wanthigh = $WANTHIGH
endif

set timest = `echo $WANTLOW | cut -c9-13,15-16`
set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/VFVF$timest
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

echo 'set VFstatus=0' >>&$TEMPCMD

foreach T ( `$SHOW_INFO 'hmi.S_720s['$wantlow'-'$wanthigh']' -q key=t_rec` ) 
  echo "$MPIEXEC -n 8 $VFISV2COMP -f -L out=$namespace.MEF_720s_fd10 in=hmi.S_720s\["$T"] in5=hmi.M_720s\["$T"] -v chi2_stop=1e-15 invert_ff=1 pol_low=0.0025" >>$TEMPCMD
end
echo "$GAPFILL ds=hmi.MEF_720s_fd10 low=$wantlow high=$wanthigh" >>$TEMPCMD
echo 'set VFstatus = $?' >>$TEMPCMD
echo 'if ($VFstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $VFstatus >retstatus' >>&$TEMPCMD
echo "echo DONE >> $TEMPLOG" >>$TEMPCMD

# execute qsub script
$QSUB -pe smp 8 -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD
 
if (-e retstatus) set retstatus = `cat $HERE/retstatus`
if ( $retstatus == 0 ) then
  @ s = `$TIME_CONVERT time=$wanthigh`
  @ sB = $s + 360
  set BHigh = `$TIME_CONVERT s=$sB zone=TAI`
  set BF_TICKET = `$MAKE_TICKET gate=hmi.BF_720s wantlow=$wantlow wanthigh=$BHigh action=5`
endif
exit $retstatus
