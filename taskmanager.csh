#! /bin/csh -f
#
# Taskmanager code
#
# Call with args task=<taskname> gate=<gatename> ticket=<ticketid>
#

set verbosemode = 1

if ($verbosemode) echo "TASKMANAGER called"
# set echo

if ($?WORKFLOW_ROOT) then
  # path for tasks and gates
  set WFDIR = $WORKFLOW_DATA  
  # path for scripts and programs
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

cd $WFDIR

#$WFCODE/scripts/checkDRMSnSUMS.csh
#set DRMSstat = $?
#set DRMSwaits = 0
#while ($DRMSstat)
#  echo -n "DRMS and/or SUMS is down at " ; date
#  if ($DRMSwaits > 360) then
#    echo DRMS down for 6 hours, quit.
#    exit 1
#  endif
#  sleep 60
#  $WFCODE/scripts/checkDRMSnSUMS.csh
#  set DRMSstat = $?
#  @ DRMSwaits = $DRMSwaits + 1
#end

set task=NOT_SPECIFIED
set gate=NOT_SPECIFIED
set ticket=NOT_SPECIFIED
while ( $#argv > 0)
  foreach keyname (task gate ticket )
    if ($1 =~ $keyname=*) then
       set $1
       break
    endif
  end # foreach
  shift
end #while
if (task == NOT_SPECIFIED || gate == NOT_SPECIFIED || ticket == NOT_SPECIFIED) then
  echo "TASKMANAGER call error, task=$task, gate=$gate, ticket=$ticket"
  exit 1
endif

if ($verbosemode) echo "TASKMANAGER called for task $task with ticket $ticket from gate $gate"
cd tasks/$task

#  Now in task directory, get static task information
# foreach keyfile (task maxrange parallelOK target state)
foreach keyfile ( maxrange parallelOK target state command)
        set $keyfile = `cat $keyfile`
end

# check that this is the right task for this gate
if ($gate != $target) then 
   echo "FAILURE $gate is not $target" 
#XXXXX return ticket too
   exit(1)
endif

# Get the path to the command
set ACTIONCOMMAND = $WFCODE/$command

#  Make an instance of this task and go to it

if (-e taskid) then
  set taskid = `$WFCODE/bin/GetNextID taskid`
else
  set taskid = `$WFCODE/bin/GetNextID taskid $task`
endif

mkdir active/$taskid

# set task state to number of active instances
echo `/bin/ls active | wc -l` > state

cd active/$taskid

echo 2 > state
mkdir subtasks
mkdir pending_tickets
mkdir ticket_return
ln $WFDIR/gates/$gate/active_tickets/$ticket ticket

#  get some gate info, such as time type
# set echo
set TYPE = `cat $WFDIR/gates/$gate/type`
set PRODUCT = `cat $WFDIR/gates/$gate/product`
set KEY = `cat $WFDIR/gates/$gate/key`
set STATUSTASK = `cat $WFDIR/gates/$gate/statustask`
set STATUSCOMMAND = $WFCODE/$STATUSTASK
if (-e $WFDIR/gates/$gate/coverage_args) then
  set COVERAGEARGS = `cat $WFDIR/gates/$gate/coverage_args`
else
  set COVERAGEARGS = none
endif

# unset echo

#  get the ticket specifics
set WANTLOW=undefined
set WANTHIGH=undefined
set TASKID=undefined
foreach key (WANTLOW WANTHIGH TASKID ACTION SPECIAL)
	set setval = `grep $key ticket`
	if ($#setval) set $setval
end

set TICKET_ACTION = $ACTION # save initial action
echo $TASKID >parent
echo $WANTLOW >wantlow
echo $WANTHIGH >wanthigh

if ($TYPE == "time") then
	set WANTLOW_t = `time_convert time=$WANTLOW `
	set WANTHIGH_t = `time_convert time=$WANTHIGH `
else
	set WANTLOW_t = $WANTLOW
	set WANTHIGH_t = $WANTHIGH
endif

# Check range of current request.  This must be done before the split of actions 4 and 5.
#  3.  if wantrange> maxrange
#    In this case recursively call this same task via tickets for parts of the range
#    a.  create action ticket for subranges to satisfy range.
#    b.  submit action tickets to gate.

@ wantrange = $WANTHIGH_t - $WANTLOW_t
if ($wantrange > $maxrange) then
	set thislow_t = $WANTLOW_t
	while ($thislow_t < $WANTHIGH_t)
		@ thishigh_t = $thislow_t + $maxrange
		if ($thishigh_t > $WANTHIGH_t) set thishigh_t = $WANTHIGH_t
                if ($TYPE == "time") then
			set thislow = `time_convert s=$thislow_t zone=TAI`
			set thishigh = `time_convert s=$thishigh_t zone=TAI`
                else
			set thislow = $thislow_t
			set thishigh = $thishigh_t
                endif
                if ($verbosemode) echo "TASKMANAGER doing partial ticket, from $thislow up to $WANTHIGH"
                if (-e pending_tickets) then
		        set num_pending = `/bin/ls  pending_tickets | wc -l`
                else
                        set num_pending = 0
                endif
                if ($verbosemode) echo "TASKMANAGER waiting to start $thislow up to $thishigh"
		while ($num_pending > $parallelOK)
			if ($verbosemode) echo "TASKMANAGER Wait for $num_pending <= $parallelOK"
			sleep 20
			if (-e $WFDIR/Keep_running) then
			else
			    echo "TaskManager Sleeping while waiting in task $taskid for ticket $ticket"
			endif
		        set num_pending = `/bin/ls  pending_tickets | wc -l`
                end
		set newticket = `$WFCODE/maketicket.csh taskid=$taskid gate=$gate wantlow=$thislow wanthigh=$thishigh action=$TICKET_ACTION special="$SPECIAL"`
		echo 1 >state
		@ thislow_t = $thislow_t + $maxrange
                if ($verbosemode) echo "TASKMANAGER new ticket $newticket registered, new wantlow = $thislow"
	end

SUBTICKETSDONE:
        if ($verbosemode) echo "TASKMANAGER all subrange parts done "
        set pendcount = `/bin/ls  pending_tickets | wc -l`
	while ($pendcount > 0)
		echo 1 >state
		sleep 20
                if (-e $WFDIR/Keep_running) then
                else
                    echo "TaskManager Sleeping while waiting in task $task for ticket $ticket"
                endif
		set pendcount = `/bin/ls  pending_tickets | wc -l`
	end

        set num_errors = 0
	foreach subticket (`/bin/ls  ticket_return/`)
		set STATUS = 5
		set substatus = `grep STATUS ticket_return/$subticket`
                if ($#substatus) set $substatus
		if ($STATUS) then
                        @ num_errors = $num_errors + 1
                        echo  Error code $STATUS returned from subticket $subticket >>FAIL_reason
                        echo Failed range subticket is: >>FAIL_reason
                        cat ticket_return/$subticket >>FAIL_reason
                        echo " " >>FAIL_reason
                endif
	end
	if ($num_errors > 0) then
                echo $num_errors range reduction subtickets had errors.  >>FAIL_reason
                goto FAILURE
        endif

        goto EXITOK
        
endif

#  2. 
# so step 2.5 will be do a show_coverage | grep UNK and make a new action==5 ticket on each UNK section.
# since only action==4 in this section, does not recurs indefinitely.
# if there are no gaps in wantrange, just drop through to exit OK.
# COVERAGEARGS comes from the gate, but MISCARGS can also come from SPECIAL on the ticket.
# If the ticket contains a SPECIAL=COVERAGEARGS=m=1 for instance it will be parsed in parts
# first extracting COVERAGEARGS=M=1 and then in the code here, to M=1 which will be added to MISCARGS
# for use in show_coverage.

set echo

set OTHER_SPECIAL
if ($TICKET_ACTION == 4) then
    if ($PRODUCT == none || $PRODUCT == NONE) then
      goto EXITOK
    endif
    if ($COVERAGEARGS == none || $COVERAGEARGS == NONE) then
      set MISCARGS = " "
    else if ($COVERAGEARGS == NEVER) then
      goto ACTION_4_OR_5
    else
      set MISCARGS = ($COVERAGEARGS)
    endif
    if ($SPECIAL != NONE) then
      # look for COVERAGEARGS
      set OLD_COVERAGE_ARGS = $COVERAGEARGS
      set SPECIAL_ARGS = (`echo $SPECIAL | sed -e 's/,/ /g'`)
      # now special_args contains a=b c=d
      set NSPECARGS = $#SPECIAL_ARGS
      set SPECARG = 1
      while ($SPECARG <= $NSPECARGS)
        if ($SPECIAL_ARGS[$SPECARG] =~ "COVERAGEARGS=*") then
          set $SPECIAL_ARGS[$SPECARG]
          set MISCARGS = ($COVERAGEARGS $MISCARGS)
        else
          set OTHER_SPECIAL = ($OTHER_SPECIAL $SPECIAL_ARGS[$SPECARG])
        endif
        @ SPECARG = $SPECARG + 1
      end 
      set COVERAGEARGS = $OLD_COVERAGE_ARGS 
    endif
    if ($#OTHER_SPECIAL == 0) set OTHER_SPECIAL = NONE
echo XXXX now MISCARGS = $MISCARGS
    #($STATUSCOMMAND $gate low=$WANTLOW high=$WANTHIGH $MISCARGS ; echo $status > stat_status) | grep UNK > gaplist
    (show_coverage $PRODUCT -iq low=$WANTLOW high=$WANTHIGH $MISCARGS ; echo $status > stat_status) | grep UNK > gaplist
    set stat_status = `cat stat_status`
    if ($stat_status) then
      # if show_coverage fails, cant check for gaps
      echo NO Show_coverage, go to ACTION=5
      goto ACTION_4_OR_5
    else
      set ngaps = `cat gaplist | wc -l`
    endif
    if ($ngaps == 0) goto EXITOK
    set igap = 1
    while ($igap <= $ngaps)
        set gapinfo = `head -n $igap gaplist | tail -1`
        set gapfirst_i = $gapinfo[2]
        set gapsize = $gapinfo[3]
	@ gaplast_i = $gapfirst_i + $gapsize 
        if ($TYPE == "time") then
            set gapfirst = `index_convert ds=$PRODUCT $KEY'_index'=$gapfirst_i`
            set gaplast = `index_convert ds=$PRODUCT $KEY'_index'=$gaplast_i`
	else
            set gapfirst = $gapfirst_i
            set gaplast = $gaplast_i
	endif
	set num_pending = `/bin/ls  pending_tickets | wc -l`
	if ($verbosemode) echo "TASKMANAGER gap filling waiting to start $gapfirst up to $gaplast"
	while ($num_pending > $parallelOK)
		if ($verbosemode) echo "TASKMANAGER Wait for $num_pending <= $parallelOK"
		sleep 20
		if (-e $WFDIR/Keep_running) then
		else
		    echo "TaskManager Sleeping while waiting in task $taskid for ticket $ticket"
		endif
		set num_pending = `/bin/ls  pending_tickets | wc -l`
	end
	set newticket = `$WFCODE/maketicket.csh taskid=$taskid gate=$gate wantlow=$gapfirst wanthigh=$gaplast action=5 special="$OTHER_SPECIAL"`
	echo 1 >state
	if ($verbosemode) echo "TASKMANAGER new ticket $newticket registered, new wantlow = $gapfirst"
	@ igap = $igap + 1
    end
    goto SUBTICKETSDONE
endif

unset echo

ACTION_4_OR_5:


# Compute Place, here the range is allowed and if wanted, already done segments have been
# bypassed in action=4.  Thus after preconditions, all of the range will be computed.

#  4.  if wantrange less or equal to max range
#      This section will only be reached for action==5 tickets.
#  In normal case where all of the requested range can be handled in a single call, do task here
#    a.  foreach ticket in precondition list prepare a wait
#        until ready ticket for this chunk.

# XXXXXXXXXXXXXXXX
# set echo
# XXXXXXXXXXXXXXXX

set num_pending = 0
foreach pregate (` /bin/ls $WFDIR/tasks/$task/preconditions/ `)
	set USELOW = $WANTLOW
	set USEHIGH = $WANTHIGH
	set ACTION = 4
	set SPECIAL = "$SPECIAL" 
        set GATEDIR = $WFDIR/gates/$pregate
        if (-e $WFDIR/tasks/$task/preconditions/$pregate/prepare_ticket) then
                set herewd = $cwd
                cd $WFDIR/tasks/$task/preconditions/$pregate/
		source prepare_ticket
		cd $herewd
        endif
	set newticket = `$WFCODE/maketicket.csh taskid=$taskid gate=$pregate wantlow=$USELOW wanthigh=$USEHIGH action=$ACTION special="$SPECIAL"`
end
echo 3 >state

# XXXXXXXXXXXXXXXX
# unset echo
# XXXXXXXXXXXXXXXX

set pendcount = `/bin/ls  pending_tickets | wc -l`
while ($pendcount > 0)
	sleep 20
        if (-e $WFDIR/Keep_running) then
	else
	    echo "TaskManager Sleeping while waiting in task $task for preconditions"
	endif
	set pendcount = `/bin/ls  pending_tickets | wc -l`
end

set num_errors = 0
foreach subticket (`/bin/ls  ticket_return/`)
        set STATUS = 5
	set substatus = `grep STATUS ticket_return/$subticket`
        if ($#substatus) set $substatus
        if ($STATUS) then
                echo PreCondition subticket $subticket returned error code $STATUS >>FAIL_reason
                echo Failed ticket is: >>FAIL_reason
                cat ticket_return/$subticket >>FAIL_reason
                echo " " >>FAIL_reason
                @ num_errors = $num_errors + 1
        endif
end
if ($num_errors > 0) then
        echo "Failure in $num_errors in PreCondition ticket()s, must giveup."  >>FAIL_reason
        goto FAILURE
endif

echo 2 >state
	
# FINALLY - execute the command to make the product

$ACTIONCOMMAND

set command_status = $?
if ($command_status) then
        echo Task command script failed with error code $command_status >>FAIL_reason
        goto FAILURE
endif

EXITOK:
    cd $WFDIR/tasks/$task/
    echo 0 >active/$taskid/state
    mv active/$taskid done
    echo `/bin/ls active | wc -l` > state
    exit 0

QUITTING:
    exit 1

FAILURE:
    cd $WFDIR/tasks/$task/
    echo 5 > active/$taskid/state
    mv active/$taskid done
    echo `/bin/ls active | wc -l` > state
    exit 1

