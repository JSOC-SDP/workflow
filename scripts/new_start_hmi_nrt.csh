#! /bin/csh -f
set WANTLOW = `cat wantlow`
set WANTHIGH = `cat wanthigh`
set NEXTWANTLOW = $WANTHIGH
set WANTHIGH_t = `time_convert time=$WANTHIGH`
@ NEXTWANTHIGH_t = $WANTHIGH_t + 360 
set NEXTWANTHIGH = `time_convert s=$NEXTWANTHIGH_t zone=TAI`
/home/phil/workflow/maketicket.csh gate=repeat_hmi_nrt wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5

# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t
# now make tickets to compute the desired products for this interval
set ARGS =  "taskid=$TASKID wantlow=$WANTLOW wanthigh=$WANTHIGH action=5"
set NRTLOS_TICKET = `/home/phil/workflow/maketicket.csh gate=hmi.LOSnrt  $ARGS `
cd pending_tickets
while ((-e $NRTLOS_TICKET))
   sleep 20
exit 0
end
