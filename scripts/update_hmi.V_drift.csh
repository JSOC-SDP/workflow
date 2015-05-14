#! /bin/csh -f
# Script to make HMI V drift coefficient tables from hmi.V_45s_nrt data
#
# set echo

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test

set HERE = $cwd 
set LOG = $HERE/runlog

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

# set CoefProgram = /home/couvidat/cvs/JSOC/bin/$JSOC_MACHINE/correction_velocities
# copied 29 Oct 2010 2:00 PM
#set CoefProgram = $WFCODE/bin/correction_velocities
set CoefProgram = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/correction_velocities

# verify that there is at least one V_drift record within 24 hours
# both before and after both the first and last record to be processed.
# step by 24 hour increments through the desired range, including the exact
# end time.

set wantlow_t = `time_convert time=$WANTLOW`
set wanthigh_t = `time_convert time=$WANTHIGH`

set need_t = $wantlow_t

while ($need_t <= $wanthigh_t)
  @ needlow_t = $need_t - 86400
  @ needhigh_t = $need_t + 86400
  set need = `time_convert zone=TAI s=$need_t`
  set needlow = `time_convert zone=TAI s=$needlow_t`
  set needhigh = `time_convert zone=TAI s=$needhigh_t`
  set n = `show_info -cq hmi.coefficients'['$needlow'-'$need']'`
  if ($n <= 0) then
    echo >>$LOG Need V_drift record for $needlow - $need 
    # make a new coef record on the nearest 06:45 or 18:45 before the needed time.
    # do this by rounding the time down to closest target.
    # do this by subtract 06h45m, divide by 12h, then mult by 12, then add 6h45m
    @ targ_t = $need_t - 24300
    @ targ_t = $targ_t / 43200
    @ targ_t = $targ_t * 43200
    @ targ_t = $targ_t + 24300
    @ targlow_t = $targ_t - 43200
    @ targhigh_t = $targ_t + 43200
    set targlow = `time_convert s=$targlow_t zone=TAI`
    set targhigh = `time_convert s=$targhigh_t zone=TAI`
    $CoefProgram begin=$targlow end=$targhigh levin=hmi.V_45s_nrt levout=hmi.coefficients >>$LOG
    if ($retstatus) then
      echo >>$LOG "FAIL $CoefProgram failed for $targ with status=$retstatus"
      goto FAILURE
    endif
  endif
  set n = `show_info -cq hmi.coefficients'['$need'-'$needhigh']'`
  if ($n <= 0) then
    echo >>$LOG Need V_drift record for $need - $needhigh 
    # make a new coef record on the nearest 06:45 or 18:45 after the needed time.
    # do this by rounding the time up to closest target.
    # do this by adding 06h45m, divide by 12h, then mult by 12, then add 6h45m
    @ targ_t = $need_t + 24300
    @ targ_t = $targ_t / 43200
    @ targ_t = $targ_t * 43200
    @ targ_t = $targ_t + 24300
    @ targlow_t = $targ_t - 43200
    @ targhigh_t = $targ_t + 43200
    set targlow = `time_convert s=$targlow_t zone=TAI`
    set targhigh = `time_convert s=$targhigh_t zone=TAI`
    $CoefProgram begin=$targlow end=$targhigh levin=hmi.V_45s_nrt levout=hmi.coefficients >>$LOG
    set retstatus = $status
    if ($retstatus) then
      echo >>$LOG "FAIL $CoefProgram failed for $targ with status=$retstatus"
      goto FAILURE
    endif
  endif
  if ($need_t == $wanthigh_t) goto DONE
  @ need_t = $need_t + 86400
  if ($need_t > $wanthigh_t) set need_t = $wanthigh_t
end

DONE:
exit 0

FAILURE:
tail -1 $LOG > FAIL_reason
# allow failures to be treated as OK for times before 9 Sept 2010.
# these may need to be done by hand in an iterative fashion.

set good_processing_t = `time_convert time=2010.09.09_TAI`

if ($wantlow_t < $good_processing_t) then
  echo "Allow drift calc to fail for earliest times. >>$LOG
  exit 0
endif

exit 1
