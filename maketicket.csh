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
set nowt = `/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/time_convert time=$now`
# @ expiret = $nowt + 86400
# change to 3 days default
@ expiret = $nowt + 259200
set expire = `/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/time_convert s=$expiret`

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

cd $WFDIR/gates/$gate

# Check reasonableness of times
# but only if gate key type is time
set keytype = `cat type`
if ($keytype == time) then
   set wantlow_t = `/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/time_convert time=$wantlow`
   set wanthigh_t = `i/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/time_convert time=$wanthigh`
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
   set oklow_t = `/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/time_convert time=$oklow`
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
