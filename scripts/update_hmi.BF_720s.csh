#! /bin/csh -f
# Script to make hmi.BF_720s_fd10
#

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test

set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set DISAMBIG = "${DRMS_BINS_INSTALL_DIR}"/disambig_v3
set GAPFILL = "${DRMS_BINS_INSTALL_DIR}"/set_gaps_missing
set INDEX_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/index_convert
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

if ( $?WORKFLOW_TEST ) then
    set namespace = "hmi_test"
    set QUE = k.q
    set QSUB = /SGE2/bin/lx-amd64/qsub
else
    set namespace = "hmi"
    if ( $JSOC_MACHINE == "linux_x86_64" ) then
      set QUE = j.q
      set QSUB = qsub
    else if ( $JSOC_MACHINE == "linux_avx" ) then
      set QUE = k.q
      set QSUB = /SGE2/bin/lx-amd64/qsub
    endif
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

@ low_s = `$TIME_CONVERT time=$WANTLOW`
@ high_s = `$TIME_CONVERT time=$WANTHIGH`
@ tdiff = $high_s - $low_s
if ( $tdiff <= 3600 ) then
  set indexhigh = `$INDEX_CONVERT ds=$product $key=$WANTHIGH`
  @ indexlast = $indexhigh - 1
  set wanthigh = `$INDEX_CONVERT ds=$product $key"_index"=$indexlast`
else
  set wanthigh = $WANTHIGH
endif
set wantlow = $WANTLOW

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = BF
set qsubname = $timename$timestr

set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/$qsubname
echo 6 > $HERE/retstatus


set ARGS = "-L AMBNEQ=100 AMBTFCTR=0.98 OFFSET=50 AMBNPAD=200 AMBNTX=30 AMBNTY=30 AMBNAP=10 AMBSEED=4 errlog=$TEMPLOG" 

# make qsub scripts

echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set HMIBstatus=6' >>&$TEMPCMD

foreach T ( `$SHOW_INFO $namespace.MEF_720s_fd10'['$wantlow'-'$wanthigh']' -q key=T_REC` )
  echo "$DISAMBIG in=$namespace.MEF_720s_fd10'['$T']' out=$namespace.BF_720s $ARGS " >> $TEMPCMD
end

echo 'set HMIBstatus = $?' >>$TEMPCMD
echo 'if ($HMIBstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $HMIBstatus >retstatus' >>&$TEMPCMD

echo "$GAPFILL ds=$namespace.BF_720s high=$wanthigh low=$wantlow" >> $TEMPCMD

# execute qsub script
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`

exit $retstatus
