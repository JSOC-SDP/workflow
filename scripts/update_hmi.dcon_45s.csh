#! /bin/csh -f

# Script to make HMI lev1.5 observables from HMI lev1 data
# #
#
# # XXXXXXXXXX test
# # set echo
# # XXXXXXXXXX test


set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

set QUE = p4.q,k.q
@ THREADS = 4
set QSUB = /SGE2/bin/lx-amd64/qsub

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
set LEV1 = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/lev1_dcon

set wantT = 19:00:00_TAI
set day1 = `echo $WANTLOW | awk -F\_ '{print $1}'`
set day2 = `echo $WANTHIGH | awk -F\_ '{print $1}'`

@ WANTLOW_s = `$TIME_CONVERT time=$WANTLOW`
@ WANTHIGH_s = `$TIME_CONVERT time=$WANTHIGH`

# Looking for 1 record per day with quality = 0 at around $wantT

set test1 = $day1'_'$wantT
set test2 = $day2'_'$wantT
@ test1_s = `$TIME_CONVERT time=$test1`
@ test2_s = `$TIME_CONVERT time=$test2`

if ( ($test1_s < $WANTLOW_s) && ($test2_s > $WANTHIGH_s) ) then
  set retstatus = 10
  echo "19:00_TAI must be included between wantlow and wanthigh"
  exit $retstatus

if ( $test1_s >= $WANTLOW_s ) then
  set T = $test1
  set day = $day1
else
  set T = $test2
  set day = $day2
endif

if ( `$SHOW_INFO hmi.Ic_45s'['$T'-'$day'_23:59:59_TAI][? quality = 0 ?]' -q n=1 key=t_rec | wc -l` == 1 ) then
  set T = `$SHOW_INFO hmi.Ic_45s'['$T'-'$day'_23:59:59_TAI][? quality = 0 ?]' -q n=1 key=t_rec`
  echo $T
else if ( `$SHOW_INFO hmi.Ic_45s'['$day'_00:00:00_TAI-'$T][? quality = 0 ?]' -q n=-1 key=t_rec | wc -l` == 1 ) then
  set T = `$SHOW_INFO hmi.Ic_45s'['$day'_00:00:00_TAI-'$T][? quality = 0 ?]' -q n=-1 key=t_rec`
  echo $T
else
  set retstatus = 9
  echo "No good data for $day"
  exit
endif

# make lev1

@ T_s = `$TIME_CONVERT time=$T`
@ T1_s = $T_s - 300   # need about 5 minutes on either side of t_rec
@ T2_s = $T_s + 300
set T1 = `$TIME_CONVERT s=$T1_s zone=TAI`
set T2 = `$TIME_CONVERT s=$T2_s zone=TAI`

set TSTMP = `echo $day | awk -F\. '{print $2$3}'`
set NAME = DCL145
set qsubname = $NAME'_'$TSTMP

set LOG = $HERE/lev1.runlog
set CMD = $HERE/$qsubname
echo 6 > $HERE/lev1.retstatus

set lev1.retstatus=0

echo "hostname >>&$LOG" >$CMD
echo "set echo >>&$LOG" >>$CMD
#echo "$LEV1 in=hmi.lev1'['$T1'-'$T2']' out=hmi.lev1_dcon psf=hmi.psf iter=25" >> $CMD
echo "Running lev1 for $T, using $T1 - $T2 filtergrams"
echo "$LEV1 in=hmi.lev1'['$T1'-'$T2']' out=hmi.lev1_dcon psf=hmi.psf iter=25"
echo 'set lev1.retstatus = $?' >>$CMD
echo 'echo $lev1.retstatus >' "$HERE/lev1.retstatus" >>$CMD
echo "rm -f $HERE/qsub_running" >>$CMD

$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD >> $LOG



# make observables

set OBS = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/HMI_observables_dcon2
set PARAMS = "levin=lev1 levout=lev1.5 wavelength=3 quicklook=0 camid=1 cadence=45.0 lev1=hmi.lev1_dcon smooth=1 rotational=0 linearity=1 -L"

set NAME = DC45
set qsubname = $NAME'_'$TSTMP
echo 6 > $HERE/obs.retstatus

set obs.retstatus=0

set QUE = p4.q
@ THREADS = 4

echo "hostname >>&$LOG" >$CMD
echo "set echo >>&$LOG" >>$CMD
#echo "$OBS begin=$T end=$T $PARAMS" >> $CMD
echo "Running observables for $T:  $OBS begin=$T end=$T $PARAMS"
echo 'set obs.retstatus = $?' >>$CMD
echo 'echo $obs.retstatus >' "$HERE/obs.retstatus" >>$CMD
echo "rm -f $HERE/qsub_running" >>$CMD

$QSUB -e $LOG -o $LOG -q $QUE $CMD >> $LOG

