#! /bin/csh -f

set WFCODE = $WORKFLOW_ROOT

# task to start next interval
set WANTLOW = `cat wantlow`
set WANTHIGH = `cat wanthigh`
set NEXTWANTLOW = $WANTHIGH
set NEXTWANTLOW_t = `time_convert time=$NEXTWANTLOW`
@ NEXTWANTHIGH_t = $NEXTWANTLOW_t + 600
set NEXTWANTHIGH = `time_convert s=$NEXTWANTHIGH_t`
$WFCODE/maketicket.csh gate=offset_vwV_fdM_test_gate wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
# now make tickets to compute the desired products for this interval
# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t
set vwV_TICKET = `$WFCODE/maketicket.csh gate=suphil.vwVtest taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH`
set fdM_TICKET = `$WFCODE/maketicket.csh gate=suphil.fdMtest taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH`
cd pending_tickets
while ((-e $vwV_TICKET) || (-e $fdM_TICKET))
   sleep 10
end
