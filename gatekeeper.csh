#! /bin/csh -f
# set echo

# gatekeeper


set CADENCE = 10
set FASTCADENCE = $CADENCE
set SLOWCADENCE = 60

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

cd $WFDIR
echo $$ >> restart.log

echo $USER > Gatekeeper_owner
echo $HOST'.'$$ > Keep_running
set keep_running = 1

while ($keep_running > 0) # KEEPRUNNING LOOP
    sed -i 's/STATUS=[0-9]/STATUS=0/' $WFDIR/ticket.test
    echo " "
    echo " "
    echo " "
    echo `/bin/date +%Y.%m.%d_%H:%M:%S`
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX "

    # gatekkeper run mode management
    cd $WFDIR

    if (-e GATEKEEPER_VERBOSE) then
      set verbosemode = `cat GATEKEEPER_VERBOSE`
    else
      set verbosemode = 1
    endif
    
    if (-e GATEKEEPER_DEBUG) then
      set debugmode = `cat GATEKEEPER_DEBUG`
    else
      set debugmode = 1
    endif

    $WFCODE/scripts/checkDRMSnSUMS.csh
    if ($?) then 
       echo "GATEKEEPER,  DRMS and/or SUMS is down, try again in a minute."
       set CADENCE = $SLOWCADENCE
       goto ALL_GATES_DONE
    else
       set CADENCE = $FASTCADENCE
    endif

    touch GATEKEEPERBUSY

    set nowtxt = `date +%Y.%m.%d_%H:%M:%S -u` 
    set now = `time_convert time=$nowtxt`

    # inspect each gate and deal with all tickets at that gate
    foreach gate (`/bin/ls gates`) # GATE LOOP
        cd $WFDIR/gates/$gate
        # get gate information attributes
        if (-e statusbusy) then
	    if ($verbosemode) echo "GATEKEEPER statustask running, skip gate for now"
continue # NEXT GATE 
        endif
        set nextupdate = `cat nextupdate`
        set updatedelta = `cat updatedelta`
        set type = `cat type`
        set actiontask = `cat actiontask`
        set gatestatus = `cat gatestatus`
        set product = `cat product`
        set statustask = `cat statustask`
        if ($gatestatus == "HOLD") then
            if ($verbosemode) echo "GATEKEEPER Gate: $gate on HOLD, skip this gate"
continue # NEXT GATE - This makes sense, since this gate is busy - go on to the next gate.
        endif
        echo starting $gate
        # Do general update if it is time
	if ($verbosemode) echo "GATEKEEPER Gate: $gate, Starting to check for update times expired"
        set nextupdatetime = `time_convert time=$nextupdate`
        if ($?) set nextupdatetime = now
	if ($verbosemode) echo "GATEKEEPER Gate: $gate, now = $now"
        if ($now >= $nextupdatetime) then
	    @ nextupdatetime = $now + $updatedelta
	    time_convert s=$nextupdatetime > nextupdate
	    echo $nowtxt > lastupdate
            touch statusbusy
            if ($gate == "clock_gate") then
                $WFCODE/$statustask $gate # do clock_gate inline
            else
                $WFCODE/$statustask $gate & 
continue # NEXT GATE 
                # stop with this gate until update is done
            endif
	endif
        set low = `cat low`
        set high = `cat high`
	if ($verbosemode) echo "GATEKEEPER Gate: $gate, Set updated low=$low, high=$high"
	if ($#low == 0 || $low == "NaN" || $#high == 0 || $high == "NaN") then
	    if ($verbosemode) echo "GATEKEEPER Gate $gate not properly initialized, try to init"
	    touch statusbusy
            $WFCODE/$statustask $gate & 
continue # NEXT GATE
            # stop with this gate until update is done
	endif
        if ($type == "time") then
	    set low_t = `time_convert time=$low`
	    set high_t = `time_convert time=$high`
        else
	    set low_t = $low
	    set high_t = $high
        endif

        # inspect all new tickets and disposition
        foreach ticket (`/bin/ls new_tickets`) # TICKET LOOP
            if ($verbosemode) echo "GATEKEEPER Start processing new ticket $ticket"
            echo $nowtxt > $WFDIR/LAST_NEWTICKET
            # get ticket key values
            foreach key (ACTION WANTLOW WANTHIGH EXPIRES) # KEY LOOP
		set setval = `grep $key new_tickets/$ticket`
                if ($#setval == 1) set $setval
            end # KEY LOOP

      	    if ($type == "time") then
		set WANTLOW_t = `time_convert time=$WANTLOW`
		set WANTHIGH_t = `time_convert time=$WANTHIGH`
	    else
		set WANTLOW_t = $WANTLOW
		set WANTHIGH_t = $WANTHIGH
	    endif

            # check for old stale ticket
            set expirestime = `time_convert time=$EXPIRES`
	    if ($expirestime < $now) then
                if ($verbosemode) echo GATEKEEPER TIMEOUT of new ticket, $expirestime "<" $now
		echo "STATUS=4" >> new_tickets/$ticket
		mv new_tickets/$ticket active_tickets
continue # NEXT TICKET
	    endif

            # disposition new tickets
	    # tickets that simply ask for status are completed and returned
	    # any request that will take processing time will have that processing started then
	    # the tickets are moved to the active ticket queue
	    # and are waited for in the next section.
            if ($verbosemode) echo "GATEKEEPER examine new ticket $ticket for action = $ACTION"

	    if ($ACTION == 1) then  # get low and high range for gate.
		echo "GATELOW=$low" >> new_tickets/$ticket
		echo "GATEHIGH=$high" >> new_tickets/$ticket
		echo "STATUS=0" >> new_tickets/$ticket
		mv new_tickets/$ticket active_tickets

	    else if ($ACTION == 2) then # check for wanted range, answer yes or no
		if ($low_t > $WANTLOW_t || $high_t < $WANTHIGH_t) then
		    if ($low_t > $WANTLOW_t) then
			echo "GATELOW=$low" >> new_tickets/$ticket
		    else
			echo "GATELOW=$WANTLOW" >> new_tickets/$ticket
		    endif
		    if ($high_t < $WANTHIGH_t) then
			echo "GATEHIGH=$high" >> new_tickets/$ticket
		    else
			echo "GATEHIGH=$WANTHIGH" >> new_tickets/$ticket
		    endif
			echo "STATUS=1" >> new_tickets/$ticket
		else
		    echo "GATELOW=$WANTLOW" >> new_tickets/$ticket
		    echo "GATEHIGH=$WANTHIGH" >> new_tickets/$ticket
		    echo "STATUS=0" >> new_tickets/$ticket
		endif
		mv new_tickets/$ticket active_tickets

	    else if ($ACTION == 3) then # wait for data, set status=2 and wait for later if data is not ready
		echo "STATUS=2" >> new_tickets/$ticket
		mv new_tickets/$ticket active_tickets

	    else if ($ACTION == 4 || $ACTION == 5) then # start actiontask to do 4 and 5
                if ($verbosemode) echo GATEKEEPER ACTION=5 started for ticket $ticket
		    echo "STATUS=3" >> new_tickets/$ticket
		    mv new_tickets/$ticket active_tickets # must happen before actiontask is started
                    set pending = `cat $WFDIR/tasks/$actiontask/state`
		    @ pending = $pending + 1
                    echo $pending >  $WFDIR/tasks/$actiontask/state
		    set TASKMANAGER = `cat $WFDIR/tasks/$actiontask/manager`
                    mkdir $WFDIR/tasks/$actiontask/logs/$ticket
		    $WFCODE/$TASKMANAGER gate=$gate task=$actiontask ticket=$ticket >>&$WFDIR/tasks/$actiontask/logs/$ticket/manager.log  &
		    echo $! > $WFDIR/tasks/$actiontask/logs/$ticket/manager.pid

	    else if ($ACTION == 6) then # make coverage map, may be slow
		    # ACTION == 6, Generate COVERAGE map
		    echo "NaN" > low
		    echo "NaN" > high
		    echo "STATUS=2" >> new_tickets/$ticket
		    mv new_tickets/$ticket active_tickets # must happen before statustask
                    touch statusbusy
                    $WFCODE/$statustask $gate low=$low high=$high &
	    endif
	    if ($verbosemode) echo GATEKEEPER moved new_tickets/$ticket to active_tickets with action=$ACTION
	end # TICKET LOOP

	if ($verbosemode) echo GATEKEEPER done with new_tickets, examine this gates action task done list

        # PROCESS EXISTING TICKETS
        # First, since only the gatekeeper may change the content of a ticket, examine this gate's
        # action task to see any tickets are in the done queue.  If they are, update their status
        # and return them to their parent task.
	#     actiontask is the task associated with this gate, the task that the ticket is sent to.
	#     TASKID is the parent task instance of the ticket.
	#     task is the taskname of the parent task -the one that wanted the processing.
	# The tickets in the task instances in the done directory have just finished
        # processing at this gate.
	# look to see if the active ticket is one that has its processing finished.
	set thisgatedir = $cwd
	cd $WFDIR/tasks/$actiontask/done/
        if ($verbosemode) echo GATEKEEPER change to $cwd
        foreach donetask ( `/bin/ls` ) # DONE TASK LOOP
            # see if there is a ticket in this gate's actiontask done queue
            # get info about this ticket.
	    if ($verbosemode) echo "GATEKEEPER look at done task $donetask"
            set lookroot = $donetask:s/-/./:e
            if ($lookroot == root) then
               echo found done task for $actiontask
               set root_done = 1
            else
               set root_done = 0
	    endif 
            foreach key (TICKET GATE TASKID) # KEY LOOP
		set setval = `grep $key $donetask/ticket`
                if ($#setval) then
		    set $setval
                else
                    set $key = VOID
	        endif
            end # DONE KEY LOOP
            if ($TASKID == VOID) then
		set TASKID = $donetask
	    endif
	    # set parenttask = `echo $TASKID | sed -e 's/-.*//'`
            set parenttask = $TASKID:s/-/./:r
            if ($TICKET != VOID) rm -f ../logs/$TICKET/manager.pid
            if ($verbosemode) echo "GATEKEEPER parent task is $parenttask"
	    ex - $donetask/ticket <<!
/STATUS/d
w
q
!
            if ($debugmode) ls -l $donetask/ticket
	    set taskstate = `cat $donetask/state`
	    if ($taskstate == 0) then
                echo "STATUS=0" >> $donetask/ticket
		mv $donetask ../archive/ok
	    else 
                echo "STATUS=5" >> $donetask/ticket
		mv $donetask ../archive/failed
		echo " " >> $WFDIR/FAILED_TASKS
		echo -n "$actiontask FAILED for " >>$WFDIR/FAILED_TASKS
		echo -n `grep WANTLOW $WFDIR/tasks/$actiontask/archive/failed/$donetask/ticket` >> $WFDIR/FAILED_TASKS
		echo -n "  " >> $WFDIR/FAILED_TASKS
		echo -n   `grep WANTHIGH $WFDIR/tasks/$actiontask/archive/failed/$donetask/ticket` >> $WFDIR/FAILED_TASKS
		echo -n "  at " >> $WFDIR/FAILED_TASKS
		date >> $WFDIR/FAILED_TASKS
		echo "     See:" $WFDIR/tasks/$actiontask/archive/failed/$donetask >> $WFDIR/FAILED_TASKS
	    endif
            if (-e ../logs/$TICKET) mv ../logs/$TICKET ../archive/logs
            if ($verbosemode) echo "GATEKEEPER done queue, move $GATE/active_tickets/$TICKET to /$parenttask/active/$TASKID/ticket_return"
            if (-e $WFDIR/gates/$GATE/active_tickets/$TICKET) then
	        mv $WFDIR/gates/$GATE/active_tickets/$TICKET $WFDIR/tasks/$parenttask/active/$TASKID/ticket_return
            endif
            if (-e $WFDIR/tasks/$parenttask/active/$TASKID/pending_tickets/$TICKET) then
	        rm $WFDIR/tasks/$parenttask/active/$TASKID/pending_tickets/$TICKET
            else if (-e $WFDIR/tasks/$parenttask/archive/ok/$TASKID/pending_tickets/$TICKET) then
                # rm $WFDIR/tasks/$parenttask/active/$TASKID/pending_tickets/$TICKET
            else
                echo "GATEKEEPER done queue, FAILED to rm $WFDIR/tasks/$parenttask/active/$TASKID/pending_tickets/$TICKET"
            endif
        end # DONE TASK
        # processing this gate's action task done list for donetask
	cd $thisgatedir

	if ($verbosemode) echo "GATEKEEPER DONE with done queue, start at $gate active_tickets"
        # examine all existing tickets, examine status then do action
        foreach ticket (`/bin/ls active_tickets`) # TICKET LOOP
	    # get ticket attributes and check for timeout
            echo $gate existing ticket  $ticket
            if ($verbosemode) echo "GATEKEEPER Start processing active ticket $ticket"
            foreach key (ACTION STATUS TASKID EXPIRES WANTLOW WANTHIGH) # KEY LOOP
		set setval = `grep $key active_tickets/$ticket`
		if ($#setval == 1) set $setval
            end # KEY LOOP
	    set EXPIRES_t = `time_convert time=$EXPIRES`
            if ($type == "time") then
		set WANTLOW_t = `time_convert time=$WANTLOW`
		set WANTHIGH_t = `time_convert time=$WANTHIGH`
	    else
		set WANTLOW_t = $WANTLOW
		set WANTHIGH_t = $WANTHIGH
	    endif
            if ($verbosemode) echo "GATEKEEPER check for timeout"

            # check expire time on working tickets
	    if ( ($STATUS == 3 || $STATUS == 2) && $EXPIRES_t < $now) then
                if ($verbosemode) echo GATEKEEPER TIMEOUT of ticket $ticket
                ex - active_tickets/$ticket <<!
/STATUS/d
w
q
!
		echo "STATUS=4" >> active_tickets/$ticket
                set STATUS=4
	        set task = `echo $TASKID | sed -e 's/-.*//'`
                if (-e WFDIR/tasks/$task/active/$TASKID) then
	            mv active_tickets/$ticket $WFDIR/tasks/$task/active/$TASKID/ticket_return
		    rm $WFDIR/tasks/$task/active/$TASKID/pending_tickets/$ticket
                else if (-e WFDIR/tasks/$task/archive/ok/$TASKID) then
		    mv active_tickets/$ticket $WFDIR/tasks/$task/archive/ok/$TASKID/ticket_return
		    rm $WFDIR/tasks/$task/archive/ok/$TASKID/pending_tickets/$ticket
                else
                    echo "GATEKEEPER can not do mv active_tickets/$ticket $WFDIR/tasks/$task/active/$TASKID/ticket_return"
                endif
	    endif
                
            # if new slow ticket type, initiate if new, else check status and wait
	    if ($STATUS == 2) then  # means getting coverage map or wait passively
		if ($verbosemode) echo "GATEKEEPER STATUS is 2"
                if (-e statusbusy) then
                    if ($verbosemode) echo "GATEKEEPER StatusCommand is running"
continue # NEXT TICKET
                    endif
		    set low = `cat low`
		    if ($#low == 0) then
		        echo XXXX got null, sleeping
		        sleep 1
		        set low = `cat low`
                    endif
	            set high = `cat high`
                    if ($#high == 0) then
                        echo XXXX got null, sleeping
                        sleep 1
                        set high = `cat high`
                    endif
		    if ($type == "time") then
		        set low_t = `time_convert time=$low`
		        set high_t = `time_convert time=$high`
		    else
		        set low_t = $low
		        set high_t = $high
		    endif
		    if ($ACTION == 3  && $WANTLOW_t >= $low_t && $WANTHIGH_t <= $high_t ) then
		        if ( $verbosemode ) echo "GATEKEEPER ACTION = 3, waiting done"
                        ex - active_tickets/$ticket << !
/STATUS/d
w
q
!
		        echo "GATELOW=$WANTLOW" >> active_tickets/$ticket
		        echo "GATEHIGH=$WANTHIGH" >> active_tickets/$ticket
		        echo "STATUS=0" >> active_tickets/$ticket
		        set STATUS = 0
		    else if ($ACTION == 6) then
		        # ACTION == 6
		        if ($verbosemode) echo "GATEKEEPER ACTION = 6"
		        # XXXXX this logic will need to change when coverage map implemented
	                if ($low != "NaN" && $high != "NaN") then # Coverage map must be complete now
                        ex - active_tickets/$ticket <<!
/STATUS/d
w
q
!
		        echo "GATELOW=$low" >> active_tickets/$ticket
		        echo "GATEHIGH=$high" >> active_tickets/$ticket
		        echo "STATUS=0" >> active_tickets/$ticket
		        set STATUS = 0
		    endif
	        endif
	        # Action was 3 or 6
	    endif
	    # STATUS == 2

            # if ticket processing is complete, return ticket to sender
	    set task = `echo $TASKID | sed -e 's/-.*//'`
	    if ($STATUS != 3 && $STATUS != 2) then   # 2,3 means still owned by some task, else return ticket
		if ($verbosemode) echo "GATEKEEPER Ticket is complete, return to owner"
		# XXXXX need to update coverage here with want range in done ticket.  For now call get coverage.
                echo Start statustask
		touch statusbusy
		$WFCODE/$statustask $gate  # wait for this to complete.
                echo done statustask
                # ticket should have been already removed from the target task's pending list
                # but check anyway
                if (-e $WFDIR/tasks/$task/active/$TASKID/ticket_return) then
                    if ($verbosemode) echo "GATEKEEPER active ticket exam, move active_tickets/$ticket to $task/active/$TASKID/ticket_return"
		        mv active_tickets/$ticket $WFDIR/tasks/$task/active/$TASKID/ticket_return
		        rm $WFDIR/tasks/$task/active/$TASKID/pending_tickets/$ticket
                    endif
		    mv active_tickets/$ticket $WFDIR/tickets_done
		endif
        end # TICKET LOOP
        # done with process existing tickets
    end # GATE LOOP
    # done with tour of all gates

    # gatekeeper loop management
ALL_GATES_DONE:
    cd $WFDIR
    rm -f GATEKEEPERBUSY
    if (!(-e Keep_running)) then
	set keep_running = 0
    else
        sed -i 's/STATUS=[0-9]/STATUS=5/ $WFDIR/ticket.test'
        echo "XXXXXXXXXXXXXXXXX Start Sleeping XXXXXXXXXXXXXXXX"
        sleep $CADENCE
    endif
 
end # KEEPRUNNING LOOP

echo Gate_Keeper Exit
exit 0

