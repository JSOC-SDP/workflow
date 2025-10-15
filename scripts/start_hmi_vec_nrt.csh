#! /bin/csh -f

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

if ( ! $?WORKFLOW_DIR ) then
    echo WORKFLOW_DIR environment variable is undefined, setting local variable to "${DRMS_SRC_INSTALL_DIR}"/workflow
    set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow
endif

set MAKE_TICKET = "${WORKFLOW_DIR}"/maketicket.csh
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

set WANTLOW = `cat wantlow`
set WANTHIGH = `cat wanthigh`

set WANTLOW_t = `$TIME_CONVERT time=$WANTLOW`
set WANTHIGH_t = `$TIME_CONVERT time=$WANTHIGH`

@ NEXTWANTLOW_t = $WANTHIGH_t
@ NEXTWANTHIGH_t = $WANTHIGH_t + 720 

set NEXTWANTLOW = `$TIME_CONVERT s=$NEXTWANTLOW_t zone=TAI`
set NEXTWANTHIGH = `$TIME_CONVERT s=$NEXTWANTHIGH_t zone=TAI`

sleep 10
$MAKE_TICKET gate=repeat_hmi_vec_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
echo -n started maketicket.csh gate=repeat_hmi_vec_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH at " " >>$WORKFLOW_DATA/watchhminrt

# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t

# now make tickets to compute the desired products for this interval
set ARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH action=5"
set NRTVEC_TICKET = `$MAKE_TICKET gate=hmi.Vector_nrt  $ARGS `
set hr1 = `echo $WANTLOW | awk -F\_ '{print $1}' | awk -F\: '{print $1}'`
set hr2 = `echo $WANTHIGH | awk -F\_ '{print $1}' | awk -F\: '{print $1}'`

cd pending_tickets
while (-e $NRTVEC_TICKET)
#while ( (-e $NRTVEC_TICKET) || (-e $FITS_TICKET) )
   sleep 60
end
exit 0
