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

set gatemaster = phil
if (-e Gatekeeper_owner) set gatemaster = `cat Gatekeeper_owner`

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
    exit 0
  endif
  # next in gate's task active_tickets
  echo Working in task $task/active
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
           set qtmp = /tmp/qstat.$$
           qstat -u $gatemaster >$qtmp

           set nq = `wc -l <$qtmp`
           @ nq = $nq - 2

           set n = 3 # skip first two lines.
           while ($n <= $nq)
             set qstatline = `head --lines $n $qtmp | tail -1`
             if ($#qstatline) then
echo Checking qstat line $qstatline
               set qid = $qstatline[1]
               set sge_o_workdir = `qstat -j $qid | grep sge_o_workdir`
               set taskid = $sge_o_workdir[2]:t
               if ($taskid == $taskinstance:t) then
                 echo Found queue program $qstatline
                 qdel $qid
                 break
               endif
             endif
             @ n = $n + 1
           end
           rm -f $qtmp
           mv $taskinstance tasks/$task/done
           echo moved $taskinstance from active to done in task $task
           if (-e tasks/$task/logs/$ticket/manager.pid) then
              set PID = `cat tasks/$task/logs/$ticket/manager.pid`
              if (!$status && $#PID) then
                 kill -9 $PID
                 rm -f tasks/$task/logs/$ticket/manager.pid
                 echo killed PID = $PID
                 exit 0
              endif
           else
              set MANAGER_PROCESS = `ps x | grep manager | grep $ticket`
              if ($#MANAGER_PROCESS > 1) then
                 set PID = $MANAGER_PROCESS[1]
                 kill -9 $PID
                 echo killed $MANAGER_PROCESS
              endif
              set MANAGER_PROCESS = " "
              exit 0
           endif
           echo Did not find active manager
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
      echo So will kill it.
      kill -9 $MANAGER_PROCESS[1]
      echo killed $MANAGER_PROCESS[1]
endif
exit 1

