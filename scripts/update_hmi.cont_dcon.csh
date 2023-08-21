#! /bin/csh -f

set drms_bins_install_dir = "${DRMS_BINS_INSTALL_DIR}"
set drms_incs_install_dir = "${DRMS_INCS_INSTALL_DIR}"
set drms_libs_install_dir = "${DRMS_LIBS_INSTALL_DIR}"
set drms_params_install_dir = "${DRMS_PARAMS_INSTALL_DIR}"
set drms_root_dir = "${DRMS_ROOT_DIR}"
set drms_scrs_install_dir = "${DRMS_SCRS_INSTALL_DIR}"
set drms_src_install_dir = "${DRMS_SRC_INSTALL_DIR}"
set drms_table_dir = "${DRMS_TABLE_DIR}"

set echo
set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

set QUE = k.q
set QSUB = /SGE2/bin/lx-amd64/qsub
set TIME_CONVERT = "${drms_bins_install_dir}"/time_convert
set SHOW_INFO = "${drms_bins_install_dir}"/show_info
set LEV1 = "${drms_bins_install_dir}"/cont_dcon

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

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
