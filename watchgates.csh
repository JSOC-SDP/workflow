#! /bin/csh -f
# monitor program

set keep_watching = 1
set thiscmd = `basename $0`
if ($thiscmd == checkgates.csh) set keep_watching = 0

if ($#argv >= 1) then
     set LIST = "*"$1"*"
else
     set LIST = "*"
endif
# echo "$LIST"

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
   set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`"_UTC" 
   echo " "; echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
   echo " "; echo " "; echo " "; echo " "
   echo -n "TIME = $nowtxt, LAST_NEWICKET = "
   cat LAST_NEWTICKET

   cd $WFDIR/gates
   foreach gate ( $LIST )
        echo " "
        cd $WFDIR/gates/$gate
        set gatestatus = `cat gatestatus`
        if ($gatestatus == "HOLD") then
            echo -n "GATE $gate is on HOLD, skip"
            cd ..
            continue
        endif
        echo -n "GATE $gate" "   for "
        cat product
        set SEQUENCE = `cat sequence_number`
        set NEXTUPDATE = `cat nextupdate`
        set LOW = `cat low`
        set HIGH = `cat high`
        echo  "     Last ticketID =  $SEQUENCE,   nextupdate =  $NEXTUPDATE", low = $LOW, high = $HIGH
        echo -n "     NEW TICKETS: "
        cd new_tickets
        set ticketlist = `/bin/ls`
        set ntickets = $#ticketlist
        if ($ntickets) then
    	      foreach ticket ($ticketlist)
                  echo -n "$ticket "
    	      end  #new
        endif
        echo  " "
        cd ../active_tickets
        echo "     ACTIVE TICKETS: "
        set ticketlist = `/bin/ls`
        set ntickets = $#ticketlist
        if ($ntickets) then
              foreach ticket ($ticketlist)
                   set STATUS = `grep STATUS $ticket`
    		   set WANTLOW = `grep WANTLOW $ticket`
    		   set WANTHIGH = `grep WANTHIGH $ticket`
    		   set ACTION = `grep ACTION $ticket`
                   set TASKID = `grep TASKID $ticket`
                   echo "         $ticket"": $STATUS, $WANTLOW, $WANTHIGH, $ACTION, $TASKID"
    	      end # active
        endif
        cd ..
   end
   if ($keep_watching) then
       sleep 10
   else
       break
   endif
end
