#! /bin/csh -f
#
# maketicket.csh gate low high
# call with taskid, gate, wantlow, wanthigh, action, special
#
# if taskid is absent then create a new taskid for the task associated
# with the target gate and make the ticket appear to be from that taskid.

set here = $cwd

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

cd $WFDIR

set ticket = $1
set gate = `echo $ticket | sed -e 's/-.*//'`

if (!( -e gates/$gate)) then
   echo "No gate matching the ticket found"
   exit 1
endif

set task = `cat gates/$gate/actiontask`
if (!( -e tasks/$task)) then
   echo "No task found for the ticket's gate"
   exit 1
endif

# Look in the terminal places for the ticket.
# at present, -root task instancew will end up in the "done" directory.
# later, when a -root ticket manager is made, they should be moved to
# the archive ok or failed pools.

# list of task instances in the done pool may be quite large,
# may need to find tasks with dates equal or maybe a day later
# then the ticket itself to manage the search.

# for now, just look at all of them

set WASFOUND = 0

while (1)

  cd $WFDIR
  set foundpath = "NOTFOUND"
  # first look in new_tickets
  if (-e gates/$gate/new_tickets/$ticket) then
    set foundpath = "PENDING"
    set WASFOUND = 1
    goto KEEPWAITING
  endif
  # next in gate's active_tickets
  if (-e gates/$gate/active_tickets/$ticket) then
    set foundpath = "PENDING"
    set WASFOUND = 1
    goto KEEPWAITING
  endif

  cd $WFDIR
  if ($foundpath == "NOTFOUND") then
    foreach queue ( tasks/$task/done tasks/$task/archive/ok tasks/$task/archive/failed )
      cd $WFDIR/$queue
      foreach taskid (`/bin/ls`)
        if ($taskid =~ "*-root") continue
        set thisticket = `grep TICKET  $taskid/ticket`
        if ($#thisticket) then
          set $thisticket  # not there is a variable TICKET containing the ticketid that casued this taskinstance
          if ($ticket == $TICKET) then
            set foundpath = $cwd/$taskid
            break
          endif
        else
          echo task instance at $cwd/$taskid has no ticket
        endif
      end
      if ($foundpath != "NOTFOUND") break
    end
  endif
  
  if ($foundpath != "NOTFOUND") then # Found the task instance for this ticket
    set ticket_status = `grep STATUS $foundpath/ticket`
    set STATUS = 999
    if ($#ticket_status) set $ticket_status 
  
    cat $foundpath/ticket
    echo TASKPATH=$foundpath
    if ($STATUS >= 5) exit 1
    exit 0
  endif

KEEPWAITING:
  if ($foundpath == "NOTFOUND") then
    if ($WASFOUND) then
      echo $ticket processing complete
    else
      echo $ticket not active
    endif
    exit 0
  endif

sleep 10
end
