#! /bin/csh -f
# Script to make AIA lev1, assumes lev0 is online
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
  set QUE = p.q,j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
  set QSUB = qsub2
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set AIA_makelev1 = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/build_lev1_aia
# set AIA_makelev1 = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/build_lev1_aia

# Make name for qsub and get times rounded to slot
set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
set timestr = `echo $wantlow  | sed -e 's/[-:]//g' -e 's/^......//' -e 's/T/_/' -e 's/..Z//'`
set timename = AIA
set qsubname = $timename$timestr

if ($indexhigh < $indexlow) then
   echo No data to process, $WANTLOW to $WANTHIGH > $HERE/runlog
   exit 0
endif

# convert to FSN
set wantlow_t =  `time_convert time=$wantlow`
set wanthigh_t = `time_convert time=$wanthigh`
set FSN_LOW =  `show_info -q key=FSN aia.lev0'[? T_OBS>='$wantlow_t' AND T_OBS<='$wanthigh_t' ?]' n=1`
set FSN_HIGH = `show_info -q key=FSN aia.lev0'[? T_OBS>='$wantlow_t' AND T_OBS<='$wanthigh_t' ?]' n=-1`

echo $FSN_LOW $FSN_HIGH

set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/$qsubname
echo 2 > retstatus

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
# XXXXXXXXXXXXXXXXXXXXX FIX THIS
echo "$AIA_makelev1 mode=fsn dsin=aia.lev0 dsout=$product instru=aia quicklook=0 bfsn=$FSN_LOW efsn=$FSN_HIGH logfile=run_log.lev1 >>&$TEMPLOG" >>$TEMPCMD
# XXXXXXXXXXXXXXXXXXXXX
echo 'set RETSTATUS = $?' >>$TEMPCMD
echo 'echo $RETSTATUS >retstatus' >>&$TEMPCMD

# execute qsub script
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
