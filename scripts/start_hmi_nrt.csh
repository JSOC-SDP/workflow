#! /bin/csh -f

set WFDIR = $WORKFLOW_DATA
set WFCODE = $WORKFLOW_ROOT

set WANTLOW = `cat wantlow`
set WANTHIGH = `cat wanthigh`

set WANTLOW_t = `time_convert time=$WANTLOW`
set WANTHIGH_t = `time_convert time=$WANTHIGH`
@ IMGWANTHIGH_t = $WANTHIGH_t - 45

@ NEXTWANTLOW_t = $WANTHIGH_t
@ NEXTWANTHIGH_t = $WANTHIGH_t + 360 

set NEXTWANTLOW = `time_convert s=$NEXTWANTLOW_t zone=TAI`
set NEXTWANTHIGH = `time_convert s=$NEXTWANTHIGH_t zone=TAI`
set IMGWANTHIGH = `time_convert s=$IMGWANTHIGH_t zone=TAI`

sleep 10
$WFCODE/maketicket.csh gate=repeat_hmi_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
echo -n started maketicket.csh gate=repeat_hmi_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH at " " >>$WFDIR/watchhminrt
date >>$WFDIR/watchhminrt

# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t
# now make tickets to compute the desired products for this interval
set ARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH action=5"
set IMGARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$IMGWANTHIGH action=5"
set NRTLOS_TICKET = `$WFCODE/maketicket.csh gate=hmi.LOSnrt  $ARGS `
set WEBIMAGE_TICKET = `$WFCODE/maketicket.csh gate=hmi.webImages  $IMGARGS `
#set VEC_TICKET = `$WFCODE/maketicket.csh gate=hmi.Vector_nrt wantlow=$WANTLOW wanthigh=$WANTHIGH action=5`
cd pending_tickets
while ((-e $NRTLOS_TICKET || -e $WEBIMAGE_TICKET))
   sleep 20
end
exit 0
