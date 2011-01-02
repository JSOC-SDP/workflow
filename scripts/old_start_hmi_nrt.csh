#! /bin/csh -f
set WFCODE = $WORKFLOW_ROOT

set WANTLOW = `cat wantlow`
set WANTLOW_t = `time_convert time=$WANTLOW`
set NOW = `date -u +%Y.%m.%d_%H:%M:%S`
set NOW_t = `time_convert time=$NOW`
@ WANTHIGH_t = $NOW_t - 360
set WANTHIGH = `time_convert s=$WANTHIGH_t zone=TAI`
#
@ NEXTWANTLOW_t = ( $WANTHIGH_t - 360 ) + 360
@ NEXTWANTHIGH_t = $NOW_t + 360 
set NEXTWANTHIGH = `time_convert s=$NEXTWANTHIGH_t zone=TAI`
set NEXTWANTLOW = `time_convert s=$NEXTWANTLOW_t zone=TAI`
$WFCODE/maketicket.csh gate=repeat_hmi_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t
# now make tickets to compute the desired products for this interval
set ARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH action=5"
set NRTLOS_TICKET = `$WFCODE/maketicket.csh gate=hmi.LOSnrt  $ARGS `
cd pending_tickets
while ((-e $NRTLOS_TICKET))
   sleep 20
exit 0
end
