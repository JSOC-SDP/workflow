#! /bin/csh -f

set echo
set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set LEV1 = "${DRMS_BINS_INSTALL_DIR}"/cont_dcon
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    set QSUB = /SGE2/bin/lx-amd64/qsub
else
    set QUE = k.q
    set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

set today = `date +%Y.%m.%d`_TAI
@ today_s = `$TIME_CONVERT time=$today`
@ first_s = $today_s - 864000   # 10 days
set first = `$TIME_CONVERT s=$first_s zone=TAI`

@ need = `$SHOW_INFO hmi.lev1'['$first'-'$today'][? fid = 10001 ?]' -cq `
echo $need
@ have = `$SHOW_INFO hmi.cont_dcon'['$first'-'$today'][? fid = 10001 ?]' -cq`
echo $have

if ( $need > $have ) then
  set todo = ()

  foreach day ( `$SHOW_INFO hmi.lev1'['$first'-'$today']' -q key=T_OBS | awk -F\_ '{print $1}' | sort -u` )
    @ dcon = `$SHOW_INFO hmi.cont_dcon'['$day'/1d]' -qc`
    if ( $dcon < 4 ) then
      set todo = ( $todo $day )
    endif
  end

  set tstmp = `echo $day | sed -e 's/[.]//g' | cut -c5-8`       
  set CMD = $HERE/CDCON$tstmp
  set LOG = $HERE/runlog
  echo "cd $HERE" >$CMD
  echo "hostname >>&$LOG" >>$CMD
  echo "set echo >>&$LOG" >>$CMD
  echo 6 > $HERE/retstatus

  foreach T ( $todo )
    echo "$LEV1 in=hmi.lev1'['$T'/1d][? fid = 10001 ?]' out=hmi.cont_dcon psf=hmi.psf iter=25 >>&$LOG" >>$CMD
  end
else
  echo "No new data"
  exit 0
endif

echo 'set TCstatus = $?' >> $CMD
echo 'echo $TCstatus >retstatus' >>$CMD

sleep 120 
$QSUB -e $LOG -o $LOG -q $QUE $CMD

set retstatus = `cat $HERE/retstatus`
exit $retstatus
