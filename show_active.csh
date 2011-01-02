#! /bin/csh -f
# monitor program


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

cd $WFDIR

while (-e GATEKEEPERBUSY)
   echo -n '.'
   sleep 1
end

clear

echo " "
set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`"_UTC" 
echo -n "TIME = $nowtxt, LAST_NEWICKET = "
cat LAST_NEWTICKET

cd $WFDIR/gates
foreach gate ( $LIST )
     cd $WFDIR/gates/$gate
     set gatestatus = `cat gatestatus`
     if ($gatestatus == "HOLD") then
         cd ..
         continue
     endif
     cd active_tickets
     set ticketlist = `/bin/ls`
     set ntickets = $#ticketlist
     if ($ntickets) then
         echo " "
         echo -n "GATE $gate" "   for "
         cat product
         foreach ticket ($ticketlist)
            set STATUS = `grep STATUS $ticket`
 	    set WANTLOW = `grep WANTLOW $ticket`
 	    set WANTHIGH = `grep WANTHIGH $ticket`
 	    set ACTION = `grep ACTION $ticket`
            set TASKID = `grep TASKID $ticket`
            echo "  $ticket"": $STATUS, $WANTLOW, $WANTHIGH, $ACTION, $TASKID"
 	 end # active
     endif
     cd ..
end

echo " "

