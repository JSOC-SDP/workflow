#! /bin/csh -f
# Script to make aia.lev1p5
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
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set AIA_makelev1p5 = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/aia_lev1p5

# Make name for qsub and get times rounded to slot
set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
set timestr = `echo $wantlow  | sed -e 's/[-:]//g' -e 's/^......//' -e 's/T/_/' -e 's/..Z//'`
set timename = LEV1p5
set qsubname = $timename$timestr

if ($indexhigh < $indexlow) then
   echo No data to process, $WANTLOW to $WANTHIGH > $HERE/runlog
   exit 0
endif

# convert to FSN
set wantlow_t =  `time_convert time=$wantlow`
set wanthigh_t = `time_convert time=$wanthigh`
#set FSN_LOW =  `show_info -q key=FSN aia.lev0'[? T_OBS>='$wantlow_t' AND T_OBS<='$wanthigh_t' ?]' n=1`
#set FSN_HIGH = `show_info -q key=FSN aia.lev0'[? T_OBS>='$wantlow_t' AND T_OBS<='$wanthigh_t' ?]' n=-1`

#echo $FSN_LOW $FSN_HIGH

set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/$qsubname
echo 2 > retstatus

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
# XXXXXXXXXXXXXXXXXXXXX FIX THIS
echo "$AIA_makelev1p5 dsinp=aia.lev1\["$wantlow"-"$wanthigh"] dsout=aia.norm_6 >>&$TEMPLOG" >>$TEMPCMD
# XXXXXXXXXXXXXXXXXXXXX
echo 'set RETSTATUS = $?' >>$TEMPCMD
echo 'echo $RETSTATUS >retstatus' >>&$TEMPCMD

# execute qsub script
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
