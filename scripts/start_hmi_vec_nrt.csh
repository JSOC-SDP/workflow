#! /bin/csh -f

set WFDIR = $WORKFLOW_DATA
set WFCODE = $WORKFLOW_ROOT

set WANTLOW = `cat wantlow`
set WANTHIGH = `cat wanthigh`

set WANTLOW_t = `time_convert time=$WANTLOW`
set WANTHIGH_t = `time_convert time=$WANTHIGH`

@ NEXTWANTLOW_t = $WANTHIGH_t
@ NEXTWANTHIGH_t = $WANTHIGH_t + 720 

set NEXTWANTLOW = `time_convert s=$NEXTWANTLOW_t zone=TAI`
set NEXTWANTHIGH = `time_convert s=$NEXTWANTHIGH_t zone=TAI`

sleep 10
$WFCODE/maketicket.csh gate=repeat_hmi_vec_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
echo -n started maketicket.csh gate=repeat_hmi_vec_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH at " " >>$WFDIR/watchhminrt

# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t

# now make tickets to compute the desired products for this interval
set ARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH action=5"
set NRTVEC_TICKET = `$WFCODE/maketicket.csh gate=hmi.Vector_nrt  $ARGS `
set hr1 = `echo $WANTLOW | awk -F\_ '{print $1}' | awk -F\: '{print $1}'`
set hr2 = `echo $WANTHIGH | awk -F\_ '{print $1}' | awk -F\: '{print $1}'`

#if ( $hr1 != $hr2 ) then
#  set FITS_TICKET = `$WFCODE/maketicket.csh gate=hmi.webFits_nrt wantlow=$WANTLOW wanthigh=$WANTHIGH action=5`
#endif

cd pending_tickets
while (-e $NRTVEC_TICKET)
#while ( (-e $NRTVEC_TICKET) || (-e $FITS_TICKET) )
   sleep 60
end
exit 0
