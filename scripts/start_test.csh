#! /bin/csh -f

set WFDIR = $WORKFLOW_DATA
set WFCODE = $WORKFLOW_ROOT

# task to start gap-filling and processing and setup recursive calling of itself
# Takes initial wantlow from calling ticket to allow catchup if wantlow is before
# end of set_missing gap filling start
set WANTLOW = `cat wantlow`
set WANTLOW_t = `time_convert time=$WANTLOW`
set NOW = `cat $WFDIR/gates/clock_gate/high`
set NOW_t = `time_convert time=$NOW`
@ WANTHIGH_t = $NOW_t - 300
set WANTHIGH = `time_convert s=$WANTHIGH_t`
#
@ NEXTWANTLOW_t = $WANTHIGH_t - 86400 + 300
@ NEXTWANTHIGH_t = $NOW_t + 300 
set NEXTWANTHIGH = `time_convert s=$NEXTWANTHIGH_t`
set NEXTWANTLOW = `time_convert s=$NEXTWANTLOW_t`
$WFCODE/maketicket.csh gate=repeat_test wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
# Now get low to fill in old gaps, 2 days below current low
@ GAPFILL_LOW_t = $WANTLOW_t - 864000
set GAPFILL_LOW = `time_convert s=$GAPFILL_LOW_t`
# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t
# now make tickets to compute the desired products for this interval
set ARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH action=4 special=FILLGAPSLOW=$GAPFILL_LOW"
echo XXXXXX MakeProductTicket with $ARGS >>~/workflow/TESTLOG
exit 0
end
