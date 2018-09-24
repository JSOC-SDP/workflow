#! /bin/csh -f

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
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info

set LEV1 = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/cont_dcon

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

  set tstmp = `echo $day | sed -e 's/[.]//g' | cut -c3-8`       
  set CMD = $HERE/CDCON.$tstmp.cmd
  set LOG = $HERE/CDCON.$tstmp.log
  echo "hostname >& $LOG" >$CMD
  echo "set echo >>&$LOG" >>$CMD
  echo "set TCstatus=6" >>&$CMD

  foreach T ( $todo )
    echo "$LEV1 in=hmi.lev1'['$T'/1d][? fid = 10001 ?]' out=hmi.cont_dcon psf=hmi.psf iter=25" >> $CMD
  end
else
  echo "No new data"
  exit 0
endif

echo 'set TCstatus = $?' >> $CMD
echo 'echo $TCstatus >retstatus' >>$CMD

#$QSUB -e $LOG -o $LOG -q $QUE $CMD

set retstatus = `cat $HERE/retstatus`
exit $retstatus
