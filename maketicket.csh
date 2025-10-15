#! /bin/csh -f
#
# maketicket.csh gate low high
# call with taskid, gate, wantlow, wanthigh, action, special
#
# if taskid is absent then create a new taskid for the task associated
# with the target gate and make the ticket appear to be from that taskid.
if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

if ( ! $?WORKFLOW_DIR ) then
    echo WORKFLOW_DIR environment variable is undefined, setting local variable to "${DRMS_SRC_INSTALL_DIR}"/workflow
    set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow
endif

set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert
set GET_NEXT_TICKET_ID = "${DRMS_BINS_INSTALL_DIR}"/GetNextID

set cmdline = ($*)

set makeSelfInstance = 0
set taskid="NOT_SPECIFIED"
set gate="NOT_SPECIFIED"
set wantlow="NOT_SPECIFIED"
set wanthigh="NOT_SPECIFIED"
set action = 4
set special = NONE

set now = `date -u +%Y.%m.%d_%H:%M:%S`
set nowt = `$TIME_CONVERT time=$now`
# @ expiret = $nowt + 86400
# change to 3 days default
@ expiret = $nowt + 259200
set expire = `$TIME_CONVERT s=$expiret`

while ( $#argv > 0)
  foreach keyname (taskid gate wantlow wanthigh action special expire)
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

cd $WORKFLOW_DATA/gates/$gate

# Check reasonableness of times
# but only if gate key type is time
set keytype = `cat type`
if ($keytype == time) then
   set wantlow_t = `$TIME_CONVERT time=$wantlow`
   set wanthigh_t = `$TIME_CONVERT time=$wanthigh`
   set project = `cat project`
   if ( $project == HMI || $project == AIA ) then
      set oklow = 1996.01.01
   else if ( $project == MDI ) then
      set oklow = 1993.01.02
   else if ( $project == WSO ) then
      set oklow = 1975.05.16
   else
      set oklow = 1601.01.02
   endif
   set oklow_t = `$TIME_CONVERT time=$oklow`
   if ($wantlow_t < $oklow_t) then
      echo "*** wantlow $wantlow is not valid for $project" 
      exit 1
   endif
   @ maxhigh = $nowt + 8640000
   if ($wanthigh_t > $maxhigh) then
      echo "*** wanthigh $wanthigh is not allowed to be more than 100 days in future."
      exit 1
   endif
endif

set ticket = `$GET_NEXT_TICKET_ID sequence_number`
# create the blank ticket
touch $ticket

set SELF_TICKET = 0
if ($taskid == NOT_SPECIFIED) then
   set SELF_TICKET = 1
   set task = `cat actiontask`
   cd $WORKFLOW_DATA/tasks/$task
   set taskid = $task'-root'
   cd active

   if (!(-e $taskid)) then
      mkdir $taskid
      echo 1 >$taskid/state
      mkdir $taskid/pending_tickets
      mkdir $taskid/ticket_return
touch $taskid/ticket
   endif
   cd $WORKFLOW_DATA/gates/$gate
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
     if (!(-e $WORKFLOW_DATA/tasks/$task/active/$taskid/ticket)) then
       ln $ticket $WORKFLOW_DATA/tasks/$task/active/$taskid/ticket
     else
       touch $WORKFLOW_DATA/tasks/$task/active/$taskid/ticket
     endif
endif

echo $ticket $cmdline >> $WORKFLOW_DATA/tasks/$task/tickets.history

# the next step must be the last since the gatekeeper will takeover
# ownership of this ticket immediately

mv $ticket new_tickets
touch $WORKFLOW_DATA/tasks/$task/active/$taskid/pending_tickets/$ticket

echo $ticket
