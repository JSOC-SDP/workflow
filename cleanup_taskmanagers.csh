#! /bin/csh -f

if ($?WORKFLOW_ROOT && $?WORKFLOW_DATA) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT and WORKFLOW_DATA env variables need to be set.
  exit 1
endif

set noglob

set TMP = /tmp/$$
rm -f $TMP
rm -f $TMP.t

# wait for gatekeeper idle
cd $WFDIR
while (-e GATEKEEPERBUSY) 
  sleep 1
  echo -n '.'
end
echo " "

if (-e restart.log) then
  grep '^On' restart.log >$TMP
  set nrestart = `wc -l <$TMP`
  if ($nrestart > 0) then
    set On_line = `head -1 $TMP`
    set gatekeeper_host = $On_line[2]
    set now_host = `hostname`
    if ($gatekeeper_host != $now_host) then
      echo Gatekeeper is running on $gatekeeper_host, NOT $now_host.
      echo exit.
      exit 1
    endif
  endif
    echo No hostname in restart.log
endif
    

ps ax | grep manager >$TMP.t
grep ticket <$TMP.t >$TMP
set n_managers = `wc -l <$TMP`

# Now $TMP should contain a list of active taskmanagers

set i_manager = 1
while ($i_manager <= $n_managers)
  set prog = `head --lines $i_manager <$TMP | tail -1`
  set thisPID = $prog[1]
  set task = NOTFOUND
  set gate = NOTFOUND
  set ticket = NOTFOUND
  set nargs = $#prog
  set iarg = 8
  while ($iarg <= $nargs)
    set thisarg = $prog[$iarg]
    if ($thisarg =~ "task=*") then
      set task = $thisarg:s/task=//
    else if ($thisarg =~ gate=*) then
      set gate = $thisarg:s/gate=//
    else if ($thisarg =~ ticket=*) then
      set ticket = $thisarg:s/ticket=//
    endif
    @ iarg = $iarg + 1
  end
  if ($task != NOTFOUND && $gate != NOTFOUND && $ticket != NOTFOUND) then
    # Now have a pipeline taskmanager process that is running, check for validity
    # there should be a manager.pid for this ticket in the active logs dir
    if (-e $WFDIR/tasks/$task/logs/$ticket/manager.pid) then
      set foundPID = `cat $WFDIR/tasks/$task/logs/$ticket/manager.pid`
      if ($thisPID == $foundPID) then
        echo $thisPID is still active
      else
        echo $thisPID does not match given tasks PID: $foundPID, so ignore
      endif
    else
      echo $thisPID does not have an active task
      if (-e $WFDIR/tasks/$task/archive/logs/$ticket) then
         echo "       " this prog is for a completed task, ticket found $WFDIR/tasks/$task/archive/logs/$ticket
         echo "       " kill $thisPID for gate=$gate task=$task ticket=$ticket
         kill -9 $thisPID
      else
         echo "       " this PID is apparently a leftover, but needs to be examined.  do nothing.
      endif
    endif
  else
    echo $thisPID does not have a valid gate, task, or ticket, so ignore
  endif
  @ i_manager = $i_manager + 1
end

rm -f $TMP
rm -f $TMP.t
