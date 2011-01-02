#! /bin/csh -f
# task to start gap-filling and processing and setup recursive calling of itself
# Takes initial wantlow from calling ticket to allow catchup if wantlow is before
# end of set_missing gap filling start

set WFDIR = $WORKFLOW_DATA
set WFCODE = $WORKFLOW_ROOT

set WANTLOW = `cat wantlow`
set WANTLOW_t = `time_convert time=$WANTLOW`
set NOW = `cat $WFDIR/clock_gate/high`
set NOW_t = `time_convert time=$NOW`
@ WANTHIGH_t = $NOW_t - 86400
set WANTHIGH = `time_convert s=$WANTHIGH_t zone=TAI`
# allow 15 days lag for data to come in
@ NEXTWANTLOW_t = $WANTHIGH_t - 1296000 + 86400
@ NEXTWANTHIGH_t = $NOW_t + 86400 
set NEXTWANTHIGH = `time_convert s=$NEXTWANTHIGH_t zone=TAI`
set NEXTWANTLOW = `time_convert s=$NEXTWANTLOW_t zone=TAI`
$WFCODE/maketicket.csh gate=repeat_daily_gate wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
# Now get low to fill in old gaps, 2 days below current low
@ GAPFILL_LOW_t = $WANTLOW_t - 172800
set GAPFILL_LOW = `time_convert s=$GAPFILL_LOW_t zone=TAI`
# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t
# now make tickets to compute the desired products for this interval
set ARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH action=4 special=FILLGAPSLOW=$GAPFILL_LOW"
set fdM96_TICKET = `$WFCODE/maketicket.csh gate=mdi.fdM_96m  $ARGS `
set vwV_TICKET = `$WFCODE/maketicket.csh gate=mdi.vwV  $ARGS `
set fdM_TICKET = `$WFCODE/maketicket.csh gate=mdi.fdM  $ARGS `
set fdV_TICKET = `$WFCODE/maketicket.csh gate=mdi.fdV  $ARGS `
cd pending_tickets
while ((-e $vwV_TICKET) || (-e $fdM_TICKET) || (-e $fdM96_TICKET) || (-e $fdV_TICKET))
   sleep 300
exit 0
end
