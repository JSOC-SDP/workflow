#! /bin/csh -f

# see if watch program of check only

set keep_watching = 1
set thiscmd = `basename $0`
if ($thiscmd == checktasks.csh) set keep_watching = 0

# monitor program, tasks only
   set noglob
   if ($#argv >= 1) then
     set LIST = "*"$1"*"
   else
     set LIST = "*"
   endif
echo "$LIST"
   unset noglob

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

set nonomatch

while (1)

   cd $WFDIR

   while (-e GATEKEEPERBUSY)
      echo -n '.'
      sleep 1
   end

   clear
   echo " "
   echo " "
   echo " "
   echo " "
   echo " "
   echo " "
   set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`"_UTC" 
   echo -n "TIME = $nowtxt, LAST_NEWICKET = "
   cat LAST_NEWTICKET

   echo " "
   cd $WFDIR/tasks
   foreach task ( $LIST )
       echo " "
       cd $WFDIR/tasks/$task
       set target = `cat target`
       set gatestatus = `cat $WFDIR/gates/$target/gatestatus`
       if ($gatestatus == "HOLD") then
            echo -n "TASK $task, target gate on HOLD, skip"
            cd ..
            continue
       endif
       set state = `cat state`
       set taskid = `cat taskid`
       echo "TASK $task"
       # DONE
       cd done
       set donelist = `/bin/ls -t`
       set ndone = $#donelist
       cd ..
       # ACTIVE
       cd active
       set activelist = `/bin/ls`
       set nactive = $#activelist
       cd ..
       # ARCHIVE
       cd archive
       set nfailed = `/bin/ls failed | wc -l`
       set nok = `/bin/ls ok | wc -l`
       cd ..
       # Print Summary
       echo "     state=$state, current=$taskid, n_active=$nactive, n_done=$ndone, n_ok=$nok n_failed=$nfailed"
       if ($ndone > 0) then
           echo "     DONE:"
           set maxdone = 2
           if ($ndone < $maxdone) set maxdone = $ndone
                foreach donetask ( $donelist[1-$maxdone] )
                    set tickstatus = `grep STATUS done/$donetask/ticket`
                    set tickname = `grep TICKET done/$donetask/ticket`
                    echo "         $donetask, $tickname, $tickstatus"
                end #donetask
                if ($ndone > $maxdone) then
                     echo "         ..."
                endif
           endif
           if ($nfailed > 0) then
                echo "     FAILED:"
                set maxfailed = 2
  	        set failedlist = `/bin/ls archive/failed | tail -$maxfailed` 
                foreach failedtask ( $failedlist )
                    set tickstatus = `grep STATUS archive/failed/$failedtask/ticket`
                    set tickname = `grep TICKET archive/failed/$failedtask/ticket`
                    set wantlow = `grep WANTLOW archive/failed/$failedtask/ticket`
                    set wanthigh = `grep WANTHIGH archive/failed/$failedtask/ticket`
                    echo "         $failedtask, $tickname, $wantlow, $wanthigh, $tickstatus"
                end #failedtask
                if ($nfailed > $maxfailed) then
                    echo "         ..."
                endif
           endif
           if ($nactive > 0) then
                echo "     ACTIVE:"
                foreach taskid ($activelist)
                    cd active/$taskid/pending_tickets
                    set pendinglist = `/bin/ls`
  	            set pending = $#pendinglist
                    cd ../../..
                    cd active/$taskid/ticket_return
                    set returnedlist = `/bin/ls`
  		    set returned = $#returnedlist
                    cd ../../..
                    if (-e active/$taskid/ticket) then
                        set tickname = `grep TICKET active/$taskid/ticket`
			set wantlow = `grep WANTLOW active/$taskid/ticket`
			set wanthigh = `grep WANTHIGH active/$taskid/ticket`
                        echo -n "         $taskid, $tickname, $wantlow, $wanthigh, $pending pending, $returned returned, state = "
                    else
                        
                        echo -n "         $taskid done"
                    endif
                    cat active/$taskid/state
                    if ($pending > 0) then
  		        echo "             PENDING tickets"
                        foreach pend_ticket ($pendinglist)
  			    echo "                 $pend_ticket"
                        end #pending
                    endif # some pending
  	        end # taskid
           endif # some active
      endif # some done
   end
   if ($keep_watching) then
      sleep 10
   else
      break
   endif
end
