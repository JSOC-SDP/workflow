#! /bin/csh -f

# cancel ticket

# set echo

set ticket = $1

set verbosemode=1

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

cd $WFDIR

set gate = `echo $ticket | sed -e 's/-.*//'`

if (!( -e gates/$gate)) then
   echo "No gate matching the ticket found"
   exit 1
endif

set task = `cat gates/$gate/actiontask`
if (!( -e tasks/$task)) then
   echo "No task found for the ticket's gate"
   set MANAGER_PROCESS = `ps x | grep manager | grep $ticket`
   if ($#MANAGER_PROCESS > 1) then
      echo BUT process found:
      echo -n "  "
      echo $MANAGER_PROCESS
   endif
   set MANAGER_PROCESS = " "
   
   exit 1
endif

# for now, just look at all of them

  cd $WFDIR
  set foundpath = "NOTFOUND"
  # first look in new_tickets
  if (-e gates/$gate/new_tickets/$ticket) then
    # in new_ticket queue, can simply delete it
    rm -f gates/$gate/new_tickets/$ticket
    echo $ticket removed
    exit
  endif
  # next in gate's task active_tickets
  foreach taskinstance ( tasks/$task/active/* )
    if (-e $taskinstance/ticket) then
      echo $ticket is active
      set tick = `grep TICKET $taskinstance/ticket`
      if ($#tick == 1) then
        set $tick
        if ($ticket == $TICKET) then
           pushd $taskinstance/pending_tickets
           set pendlist = `/bin/ls`
           foreach pending ( $pendlist ) 
             echo Found pending ticket : $pending
             $WFCODE/cancelticket.csh $pending
           end
           popd
           mv $taskinstance tasks/$task/done
           echo moved $taskinstance from active to done in task $task
           set MANAGER_PROCESS = `ps x | grep manager | grep $ticket`
           if ($#MANAGER_PROCESS > 1) then
              set PID = $MANAGER_PROCESS[1]
              kill -9 $PID
              echo killed $MANAGER_PROCESS
           endif
           set MANAGER_PROCESS = " "
           exit 0
        endif
      endif
    endif
  end

echo Failed to find ticket.
set MANAGER_PROCESS = `ps x | grep manager | grep $ticket`
if ($#MANAGER_PROCESS > 1) then
      echo BUT process found:
      echo -n "  "
      echo $MANAGER_PROCESS
endif
exit 1

