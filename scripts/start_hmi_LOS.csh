#! /bin/csh -f

set WFDIR = $WORKFLOW_DATA
set WFCODE = $WORKFLOW_ROOT

set WANTLOW = `cat wantlow`
set WANTHIGH = `cat wanthigh`

set WANTLOW_t = `time_convert time=$WANTLOW`
set WANTHIGH_t = `time_convert time=$WANTHIGH`
@ IMGWANTHIGH_t = $WANTHIGH_t - 45

@ NEXTWANTLOW_t = $WANTHIGH_t
@ NEXTWANTHIGH_t = $WANTHIGH_t + 1440 

set NEXTWANTLOW = `time_convert s=$NEXTWANTLOW_t zone=TAI`
set NEXTWANTHIGH = `time_convert s=$NEXTWANTHIGH_t zone=TAI`
set IMGWANTHIGH = `time_convert s=$IMGWANTHIGH_t zone=TAI`

$WFCODE/maketicket.csh gate=repeat_hmi_LOS wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5

# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t
# now make tickets to compute the desired products for this interval
set ARGS =     "taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH action=5"
set IMGARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$IMGWANTHIGH action=5"
set LOS_TICKET =      `$WFCODE/maketicket.csh gate=hmi.LOS  $ARGS `
set WEBIMAGE_TICKET = `$WFCODE/maketicket.csh gate=hmi.webImages  $IMGARGS `
cd pending_tickets
while ((-e $LOS_TICKET || -e $WEBIMAGE_TICKET))
   sleep 120
end
exit 0
