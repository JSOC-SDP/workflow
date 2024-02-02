#! /bin/csh -f
# Script to make AIA lev1, assumes lev0 is online
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test
set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set AIA_MAKE_LEV1 = "${DRMS_BINS_INSTALL_DIR}"/build_lev1_aia
set INDEX_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/index_convert
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

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

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

# Make name for qsub and get times rounded to slot
set indexlow = `$INDEX_CONVERT ds=$product $key=$WANTLOW`
set indexhigh = `$INDEX_CONVERT ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `$INDEX_CONVERT ds=$product $key"_index"=$indexlow`
set wanthigh = `$INDEX_CONVERT ds=$product $key"_index"=$indexhigh`
set timestr = `echo $wantlow  | sed -e 's/[-:]//g' -e 's/^......//' -e 's/T/_/' -e 's/..Z//'`
set timename = AIA
set qsubname = $timename$timestr

if ($indexhigh < $indexlow) then
   echo No data to process, $WANTLOW to $WANTHIGH > $HERE/runlog
   exit 0
endif

# convert to FSN
set wantlow_t =  `$TIME_CONVERT time=$wantlow`
set wanthigh_t = `$TIME_CONVERT time=$wanthigh`
set FSN_LOW =  `$SHOW_INFO -q key=FSN aia.lev0'[? T_OBS>='$wantlow_t' AND T_OBS<='$wanthigh_t' ?]' n=1`
set FSN_HIGH = `$SHOW_INFO -q key=FSN aia.lev0'[? T_OBS>='$wantlow_t' AND T_OBS<='$wanthigh_t' ?]' n=-1`

echo $FSN_LOW $FSN_HIGH

set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/$qsubname
echo 2 > retstatus

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
# XXXXXXXXXXXXXXXXXXXXX FIX THIS
echo "$AIA_MAKE_LEV1 mode=fsn dsin=aia.lev0 dsout=$product instru=aia quicklook=0 bfsn=$FSN_LOW efsn=$FSN_HIGH logfile=run_log.lev1 >>&$TEMPLOG" >>$TEMPCMD
# XXXXXXXXXXXXXXXXXXXXX
echo 'set RETSTATUS = $?' >>$TEMPCMD
echo 'echo $RETSTATUS >retstatus' >>&$TEMPCMD

# execute qsub script
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
