#
# Script to wait for HMI cosmic ray tables to be filled in
#
# this is run in the task instance directory where there is a 'ticket' file that specifies
# the request.

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test

set HERE = $cwd 
set LOG = $HERE/runlog
set BABBLE = $HERE/babble

date > $LOG

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set. >>$LOG
env >>$LOG
  exit 1
endif

# The first part of this code is rdundant with the code for lev1 by FSN
# This code will timeout after a day of waiting

# Check end of hmi.lev1 for coverage, wait if needed.
# the files containing wantlow and wanthigh are in the current dir when this is called.


set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`
echo "wanthigh = " $wanthigh >> $LOG
echo "wantlow = " $wantlow >> $LOG

set special = `grep SPECIAL ticket`
if ($#special > 0) then
echo variable special is $special >> $LOG
  set $special
echo variable SPECIAL is $SPECIAL >> $LOG
  if ($SPECIAL == NONE) then
    set CAMERA = 2
  else
    set $SPECIAL
echo now variable SPECIAL is $SPECIAL >> $LOG
  endif
else
  set CAMERA = 2
endif

# new way
set CAMERA=2
set special = `grep SPECIAL ticket`
if ($#special > 0) then
echo variable special is $special >> $LOG
  set $special
endif

# this is now done as a precondition ticket
# set wanthigh_t = `time_convert time=$wanthigh`
# set lev1end = `show_info key=T_OBS -q hmi.lev1'[$]'`
# set lev1end_t = `time_convert time=$lev1end`
# set n_try = 0
# while ($lev1end_t < $wanthigh_t)
#     echo -n '.' >>$BABBLE
#     @ n_try = $n_try + 1
#     if ($n_try > 288) then
#       echo "Timeout after 1 day, hmi.lev1 records not available" >>$LOG
#       set retstatus = 1
#       goto FAILUREEXIT
#     endif
#     sleep 300
#     set lev1end = `show_info key=T_OBS -q hmi.lev1'[$]'`
#     set lev1end_t = `time_convert time=$lev1end`
# end
# 
# # now find the first and last FSN for the wanted range.  Must use lev0 since may be gaps in lev1
# set wantlow_t = `time_convert time=$wantlow`
# @ wantlow_t = $wantlow_t - 5
# @ wanthigh_t = $wanthigh_t + 5
# set First_FSN = `show_info -q key=FSN hmi.lev0a'[? T_OBS>'$wantlow_t' AND T_OBS<'$wanthigh_t' ?]' n=1`
# set Last_FSN = `show_info -q key=FSN hmi.lev0a'[? T_OBS>'$wantlow_t' AND T_OBS<'$wanthigh_t' ?]' n=-1`
# echo "First_FSN = " $First_FSN >> $LOG
# echo "Last_FSN = " $Last_FSN >> $LOG
# 
# # now wait until lev1 rnge is filled in
# set N_UNK = `show_coverage -q ds=hmi.lev1 key=FSN low=$First_FSN high=$Last_FSN | grep UNK | wc -l`
# set n_try = 0
# while ($N_UNK > 0)
#     echo -n '.' >>$BABBLE
#     @ n_try = $n_try + 1
#     if ($n_try > 288) then
#       echo "Timeout after 1 day $N_UNK hmi.lev1 records not available" >>$LOG
#       set retstatus = 1
#       goto FAILUREEXIT
#     endif
#     sleep 300
#     set N_UNK = `show_coverage -q ds=hmi.lev1 key=FSN low=$First_FSN high=$Last_FSN | grep UNK | wc -l`
# end

# finally compare lev1 records to cosmic ray records to make sure there are cosmic ray
# tables for every useful lev1 record.

set FFSN = `show_info hmi.lev1'['$wantlow'-'$wanthigh']' n=1 -q key=FSN`
set LFSN = `show_info hmi.lev1'['$wantlow'-'$wanthigh']' n=-1 -q key=FSN`
# echo $FFSN $LFSN
# set QUALMASK = 0x2F000
set QUALMASK = 192512
show_info hmi.lev1'[]['$FFSN'-'$LFSN'][? FID >= 10050 AND FID < 11000 ?][? (QUALITY & '$QUALMASK') = 0 ?][? CAMERA = '$CAMERA' ?]' -q key=FSN > FSN_lev1
show_info hmi.cosmic_rays'[]['$FFSN'-'$LFSN'][? FID >= 10050 AND FID < 11000 ?][? CAMERA = '$CAMERA' ?]' -q key=FSN > FSN_cosmic
set N_NOCR = `comm FSN_lev1 FSN_cosmic -23 | wc -l`
echo "Lev1 records without cosmic ray records count = " $N_NOCR >>$LOG

# If more than a small number, 10 cosmic ray records missing, must exit since no processing will be pending.

if ($N_NOCR > 100) then
  echo "$N_NOCR lev1 records are missing matching cosmic_ray records. " >>FAIL_reason
  echo "The missing cosmic_ray records are FSNs: ">>FAIL_reason
  comm FSN_lev1 FSN_cosmic -23 >>FAIL_reason
  echo " " >>FAIL_reason
  set retstatus = 3
  goto FAILUREEXIT
endif

exit 0

FAILUREEXIT:

exit $retstatus
