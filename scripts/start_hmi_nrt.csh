#! /bin/csh -f

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

SET MAKE_TICKET = "$WORKFLOW_DIR/maketicket.csh"
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

set WANTLOW = `cat wantlow`
set WANTHIGH = `cat wanthigh`

set WANTLOW_t = `$TIME_CONVERT time=$WANTLOW`
set WANTHIGH_t = `$TIME_CONVERT time=$WANTHIGH`
@ IMGWANTHIGH_t = $WANTHIGH_t - 45

@ NEXTWANTLOW_t = $WANTHIGH_t
@ NEXTWANTHIGH_t = $WANTHIGH_t + 360 

set NEXTWANTLOW = `$TIME_CONVERT s=$NEXTWANTLOW_t zone=TAI`
set NEXTWANTHIGH = `$TIME_CONVERT s=$NEXTWANTHIGH_t zone=TAI`
set IMGWANTHIGH = `$TIME_CONVERT s=$IMGWANTHIGH_t zone=TAI`

sleep 10
$MAKE_TICKET gate=repeat_hmi_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
echo -n started maketicket.csh gate=repeat_hmi_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH at " " >>$WORKFLOW_DATA/watchhminrt
date >>$WORKFLOW_DATA/watchhminrt

# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t
# now make tickets to compute the desired products for this interval
set ARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH action=5"
set IMGARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$IMGWANTHIGH action=5"
set NRTLOS_TICKET = `$MAKE_TICKET gate=hmi.LOSnrt  $ARGS `
set WEBIMAGE_TICKET = `$MAKE_TICKET gate=hmi.webImages  $IMGARGS `

cd pending_tickets
while ((-e $NRTLOS_TICKET || -e $WEBIMAGE_TICKET))
   sleep 20
end
exit 0
