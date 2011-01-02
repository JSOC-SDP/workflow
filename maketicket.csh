#! /bin/csh -f
#
# maketicket.csh gate low high
# call with taskid, gate, wantlow, wanthigh, action, special
#
# if taskid is absent then create a new taskid for the task associated
# with the target gate and make the ticket appear to be from that taskid.

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

# echo $0 $* >> history.tickets
set cmdline = ($*)

set makeSelfInstance = 0
set taskid="NOT_SPECIFIED"
set gate="NOT_SPECIFIED"
set wantlow="NOT_SPECIFIED"
set wanthigh="NOT_SPECIFIED"
set action = 4
set special = NONE

set now = `date -u +%Y.%m.%d_%H:%M:%S`
set nowt = `time_convert time=$now`
@ expiret = $nowt + 86400
set expire = `time_convert s=$expiret`

while ( $#argv > 0)
  foreach keyname (taskid gate wantlow wanthigh action special)
    if ($1 =~ $keyname=*) then
       set $1
       break
    endif
    end # foreach
  shift
  end #while

if ($wantlow == NOT_SPECIFIED) then
   echo MUST provide wantlow=value argument
   exit 1
endif
if ($wanthigh == NOT_SPECIFIED) then
   echo MUST provide wanthigh=value argument
   exit 1
endif
if ($gate == NOT_SPECIFIED) then
   echo MUST provide gate=value argument
   exit 1
endif

cd $WFDIR/gates/$gate
set ticket = `$WFCODE/bin/GetNextID sequence_number`
# create the blank ticket
touch $ticket

set SELF_TICKET = 0
if ($taskid == NOT_SPECIFIED) then
   set SELF_TICKET = 1
   set task = `cat actiontask`
   cd $WFDIR/tasks/$task
   set taskid = $task'-root'
   # if (-e taskid) then
       # set taskid = `$WFCODE/bin/GetNextID taskid`
   # else
       # set taskid = `$WFCODE/bin/GetNextID taskid $task'-19930101-000'`
   # endif
   cd active
   # mkdir active/$taskid
   # cd active/$taskid
   # echo 1 >state
   if (!(-e $taskid)) then
      mkdir $taskid
      echo 1 >$taskid/state
      mkdir $taskid/pending_tickets
      mkdir $taskid/ticket_return
touch $taskid/ticket
   endif
   cd $WFDIR/gates/$gate
else
   set task = `echo $taskid | sed -e 's/-.*//'`
endif

echo "TICKET=$ticket"    >> $ticket
echo "GATE=$gate"        >> $ticket
echo "ACTION=$action"         >> $ticket
echo "EXPIRES=$expire" >> $ticket
echo "SPECIAL=$special"     >> $ticket
echo "WANTLOW=$wantlow"      >> $ticket
echo "WANTHIGH=$wanthigh"     >> $ticket
echo "TASKID=$taskid"       >> $ticket

if ($SELF_TICKET) then
     if (!(-e $WFDIR/tasks/$task/active/$taskid/ticket)) then
       ln $ticket $WFDIR/tasks/$task/active/$taskid/ticket
     else
       touch $WFDIR/tasks/$task/active/$taskid/ticket
     endif
endif

echo $ticket $cmdline >> $WFDIR/tasks/$task/tickets.history

# touch $WFDIR/tasks/$task/active/$taskid/pending_tickets/$ticket

# the next step must be the last since the gatekeeper will takeover
# ownership of this ticket immediately

mv $ticket new_tickets
touch $WFDIR/tasks/$task/active/$taskid/pending_tickets/$ticket

echo $ticket
