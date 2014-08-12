#! /bin/csh -f
# Script to make hmi.ME_720s_fd10
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test

set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j8.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = b8.q
  set QSUB = qsub2
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set VFISV = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/vfisv

set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

# round times to a slot
#set indexlow = `index_convert ds=$product $key=$WANTLOW`
#set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
#@ indexhigh = $indexhigh - 1
#set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
#set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
#set timestr = `echo $wantlow  | sed -e 's/[._:]//g' -e 's/^.......//' -e 's/TAI//'`
set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = VFISV
set qsubname = $timename$timestr

#if ($indexhigh < $indexlow) then
#   echo No data to process, $WANTLOW to $WANTHIGH > $HERE/runlog
#   exit 0
#endif

set TEMPLOG = $HERE/runlog
set babble = $HERE/babble
set TEMPCMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

# make qsub scripts
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set VFISVstatus=0' >>&$TEMPCMD

echo "setenv MPI_MAPPED_STACK_SIZE 100M" >> $TEMPCMD
echo "setenv MPI_MAPPED_HEAP_SIZE 100M" >> $TEMPCMD
echo "setenv KMP_STACKSIZE 16M" >> $TEMPCMD
echo "unlimit" >> $TEMPCMD
echo "limit core 0" >> $TEMPCMD
if ( $JSOC_MACHINE == "linux_x86_64" ) then
  echo "/home/jsoc/mpich2/bin/mpdboot --ncpus=8" >> $TEMPCMD
endif
echo "/home/jsoc/mpich2/bin/mpiexec -n 8 $VFISV out=hmi.ME_720s_fd10 in=hmi.S_720s\["$wantlow"-"$wanthigh"] in5=hmi.M_720s\["$wantlow"-"$wanthigh"] -v chi2_stop=1e-15" >>&$TEMPLOG" >>$TEMPCMD
#echo "/home/jsoc/mpich2/bin/mpdexit " >> $TEMPCMD
echo 'set VFISVstatus = $?' >>$TEMPCMD
echo 'if ($VFISVstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $VFISVstatus >retstatus' >>&$TEMPCMD

# execute qsub script
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
