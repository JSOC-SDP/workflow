#! /bin/csh -f
# Script to make hmi.S_5760s from hmi.S_720s data.
#

# XXXXXXXXXX test
# set echo
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
  set QUE = j.q
  @ THREADS = 1
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = p4.q
  @ THREADS = 4
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`
set echo

set IQUVprogram = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/HMI_IQUV_averaging

# round times to a slot
set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
if ( $indexhigh != $indexlow ) then
  @ indexhigh = $indexhigh - 1
endif
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = S96
set qsubname = $timename$timestr

if ($indexhigh < $indexlow) then
   echo No data to process, $WANTLOW to $WANTHIGH > $HERE/runlog
   exit 0
endif

@ T1 = `time_convert time=$wantlow`
@ T2 = `time_convert time=$wanthigh`

### Mod-L Times
### 2015.05.05_20:02:26.11_UTC - 2015.05.05_21:08:24.23_UTC  FSN 88858906-88861017 s=1209931381-1209935339
### 2015.05.15_00:00:01.73_UTC - 2015.05.15_21:00:54.23_UTC  FSN 89271149-89311497 s=1210723237-1210798889
### 2016.03.08_04:32:25.11_UTC - 2016.03.08_11:30:53.23_UTC  FSN 102999325-103012716 s=1236486781-1236511889
### 2016.04.13_19:12:55.11_UTC - present                     FSN 104683793--->       s=1239650011--->
### IQUV_args = "-L wavelength=3 camid=0 cadence=90.0 npol=8 size=48 lev1=hmi.lev1 quicklook=0 linearity=1 average=96 rotational=0"

@ L1 = 1209931381
@ L2 = 1209935339
@ L3 = 1210723237
@ L4 = 1210798889
@ L5 = 1236486781
@ L6 = 1236511889
@ L7 = 1239650011

### Mod-C Times
### 2010.05.01_00:00:00.85_UTC - 2010.08.01_05:20:42.10_UTC  FSN 4612151-88858905 s=1051747235-1059715276
### 2015.05.05_21:10:41.11_UTC - 2015.05.14_23:59:59.86_UTC  FSN 88861018-89271148 s=1209935476-1210723235
### 2015.05.15_21:01:41.11_UTC - 2016.03.08_04:32:23.23_UTC  FSN 89311498-102999324 s=1210798936-1236486779
### 2016.03.08_11:32:25.11_UTC - 2016.04.13_19:12:51.90_UTC  FSN 103012717-104683792 s=1236511981-1239650008
### IQUV_args = "-L wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1 quicklook=0 linearity=1 average=96 rotational=0"

@ C1 = 1051747235
@ C2 = 1059715276
@ C3 = 1209935476
@ C4 = 1210723235
@ C5 = 1210798936
@ C6 = 1236486779
@ C7 = 1236511981
@ C8 = 1239650008

if ( ($T1 && $T2 >= $L1 && $T1 && $T2 <= $L2) || ($T1 && $T2 >= $L3 && $T1 && $T2 <= $L4) || ($T1 && $T2 >= $L5 && $T1 && $T2 <= $L6) || ( $T1 && $T2 >= $L7 ) ) then
  set IQUV_args = "-L wavelength=3 camid=0 cadence=90.0 npol=8 size=48 lev1=hmi.lev1 quicklook=0 linearity=1 average=96 rotational=0"
else if ( ($T1 && $T2 >= $C1 && $T1 && $T2 <= $C2) || ($T1 && $T2 >= $C3 && $T1 && $T2 <= $C4) || ($T1 && $T2 >= $C5 && $T1 && $T2 <= $C6) || ($T1 && $T2 >= $C7 && $T1 && $T2 <= $C8) ) then
  set IQUV_args = "-L wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1 quicklook=0 linearity=1 average=96 rotational=0"
else
  ###  Time spans both Mod-C and Mod-L runs.  
  exit 10
endif
  
set TEMPLOG = $HERE/runlog
set babble = $HERE/babble
set TEMPCMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
#echo "setenv OMP_NUM_THREADS 8" >>$TEMPCMD
echo "setenv OMP_NUM_THREADS $THREADS" >>$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus=0' >>&$TEMPCMD

echo "$IQUVprogram begin="$wantlow"  end="$wanthigh $IQUV_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set retstatus = $?' >>$TEMPCMD
echo 'if ($retstatus) goto DONE' >>&$TEMPCMD


echo 'DONE:' >>$TEMPCMD
echo 'echo $retstatus >retstatus' >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD

# execute qsub script
touch $HERE/qsub_running
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if ( -e $HERE/retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
