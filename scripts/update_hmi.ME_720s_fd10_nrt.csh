#! /bin/csh -f
# Script to make hmi.ME_720s_fd10_nrt
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

set VFISV = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/vfisv_harp
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info

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
set timename = VFnrt
set qsubname = $timename$timestr

#if ($indexhigh < $indexlow) then
#   echo No data to process, $WANTLOW to $WANTHIGH > $HERE/runlog
#   exit 0
#endif

set TEMPLOG = $HERE/runlog
set babble = $HERE/babble
set TEMPCMD = $HERE/$qsubname
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
#if ( $JSOC_MACHINE == "linux_x86_64" ) then
#  echo "/home/jsoc/mpich2/bin/mpdboot --ncpus=8" >> $TEMPCMD 
#endif
echo "sleep 10" >> $TEMPCMD

echo 'set VFnrtstatus=0' >>&$TEMPCMD

foreach T ( `$SHOW_INFO JSOC_DBUSER=production 'hmi.S_720s_nrt['$wantlow'-'$wanthigh']' -q key=t_rec` ) 
  @ i = 1
  @ n = `$SHOW_INFO hmi.MHarp_720s_nrt'[]['$T']' -cq`

  ## wait 40 minutes for harps to process if necessary
  while ( ($n <= 0) && ($i < 20) )
    set last = `$SHOW_INFO hmi.MHarp_720s_nrt n=-1 key=t_obs -q`
    echo "n=$n : no harp data for $T, last harp is $last" >> $TEMPLOG
    sleep 180
    @ n = `$SHOW_INFO hmi.MHarp_720s_nrt'[]['$T']' -cq`
    @ i ++
  end
  if ( ($n <= 0) && ($i == 20) ) then
    echo 'set VFnrtstatus = 0' >>$TEMPCMD
    echo 'echo No HARPs' >>$TMPCMD
#    echo 'goto DONE' >>&$TEMPCMD
#   exit
  else  
    echo "date" >>$TEMPCMD
    echo "$MPIEXEC -n 8 $VFISV out=hmi.ME_720s_fd10_nrt in=hmi.S_720s_nrt\["$T"] in3=hmi.MHarp_720s_nrt'[]['"$T"']' in5=hmi.M_720s_nrt\["$T"] -v" >>$TEMPCMD
    echo "date" >>$TEMPCMD
  endif
end

echo 'set VFnrtstatus = $?' >>$TEMPCMD
echo 'if ($VFnrtstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $VFnrtstatus >retstatus' >>&$TEMPCMD
echo "echo DONE >> $TEMPLOG" >>$TEMPCMD
# execute qsub script


$QSUB -sync yes -l h_rt=36:00:00 -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD


if (-e retstatus) set retstatus = `cat $HERE/retstatus`
if ( $retstatus ) then
  exit $retstatus
else 
  set SHP_TICKET = `$WFCODE/maketicket.csh gate=hmi.sharp_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`
endif
#if ( $retstatus == 0 ) then
#  set SHP_TICKET = `$WFCODE/maketicket.csh gate=hmi.sharp_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`
#endif
exit $retstatus
