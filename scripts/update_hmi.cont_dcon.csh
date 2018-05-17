#! /bin/csh -f

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

set LEV1 = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/lev1_dcon

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set last_cal = `$SHOW_INFO hmi.lev1_cal'[$]' -q key=t_obs`
@ last_cal_s = `$TIME_CONVERT time=$last_cal`
set last_lev1 = `$SHOW_INFO hmi.lev1'[$]' -q key=t_obs`
@ last_lev1_s = `$TIME_CONVERT time=$last_lev1`
@ wanthigh_s = `$TIME_CONVERT time=$WANTHIGH`

if ( ($wanthigh_s > $last_cal_s) && ($wanthigh_s <= $last_lev1_s) ) then
  set series = hmi.lev1
else if ( $wanthigh_s <= $last_cal_s ) then
  set series = hmi.lev1_cal
else
  exit 2
endif

set tstmp = `echo $WANTLOW | awk -F\_ '{print $1}' | sed -e 's/[.]//g' | cut -c3-8`
set CMD = $HERE/TC$tstmp
set LOG = $HERE/runlog

echo "hostname >>&$LOG" >$CMD
echo "set echo >>&$LOG" >>$CMD
echo "set TCstatus=6" >>&$CMD

foreach fsn ( `show_info $series'['$WANTLOW'-'$WANTHIGH'][? FID = 10001 ?]' -q key=fsn` )
  echo "$LEV1 in=$series'[]['$fsn']' out=hmi.cont_dcon psf=hmi.psf iter=25" >> $CMD
end

echo 'set TCstatus = $?' >> $CMD
echo 'echo $TCstatus >retstatus' >>$CMD

$QSUB -e $LOG -o $LOG -q $QUE $CMD

set retstatus = `cat $HERE/retstatus`
exit $retstatus
