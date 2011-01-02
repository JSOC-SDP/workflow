#
# Script to wait for HMI lev1 data to be filled in
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

# Check end of hmi.lev1 for coverage, wait if needed.
# the files containing wantlow and wanthigh are in the current dir when this is called.

# first wait until hmi.lev1 at least includes wanthigh
set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`
echo "wanthigh = " $wanthigh >> $LOG
echo "wantlow = " $wantlow >> $LOG

set wanthigh_t = `time_convert time=$wanthigh`
set lev1end = `show_info key=T_OBS -q hmi.lev1'[$]'`
set lev1end_t = `time_convert time=$lev1end`
while ($lev1end_t < $wanthigh_t)
    echo -n '.' >>$BABBLE
    sleep 300
    set lev1end = `show_info key=T_OBS -q hmi.lev1'[$]'`
    set lev1end_t = `time_convert time=$lev1end`
end

# now find the first and last FSN for the wanted range.  Must use lev0 since may be gaps in lev1
set wantlow_t = `time_convert time=$wantlow`
@ wantlow_t = $wantlow_t - 5
@ wanthigh_t = $wanthigh_t + 5
set First_FSN = `show_info -q key=FSN hmi.lev0a'[? T_OBS>'$wantlow_t' AND T_OBS<'$wanthigh_t' ?]' n=1`
set Last_FSN = `show_info -q key=FSN hmi.lev0a'[? T_OBS>'$wantlow_t' AND T_OBS<'$wanthigh_t' ?]' n=-1`
echo "First_FSN = " $First_FSN >> $LOG
echo "Last_FSN = " $Last_FSN >> $LOG

# Wait until all FSN in the range are accounted for
@ n_expect = 1 + $Last_FSN - $First_FSN
set n_have = `show_info -cq hmi.lev1'[]['$First_FSN'-'$Last_FSN']'`
set n_tries = 0
while ($n_have < $n_expect)
  sleep 600
  echo -n '.' >>$BABBLE
  @ n_tries = $n_tries + 1
  if ($n_tries > 144) then
      echo "Timeout after 1 day $n_have found, expect $n_expect hmi.lev1 records" >>$LOG
      exit 1
  endif
end

# now wait until lev1 rnge is filled in
# set N_UNK = `show_coverage -q ds=hmi.lev1 key=FSN low=$First_FSN high=$Last_FSN | grep UNK | wc -l`
# set n_try = 0
# while ($N_UNK > 0)
    # echo -n '.' >>$BABBLE
    # @ n_try = $n_try + 1
    # if ($n_try > 288) then
      # echo "Timeout after 1 day $N_UNK hmi.lev1 records not available" >>$LOG
      # exit 1
    # endif
    # sleep 300
    # set N_UNK = `show_coverage -q ds=hmi.lev1 key=FSN low=$First_FSN high=$Last_FSN | grep UNK | wc -l`
# end

exit 0
