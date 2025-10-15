#! /bin/csh -f
# monitor program
if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

if ($#argv >= 1) then
    set LIST = "*"$1"*"
else
    set LIST = "*"
endif
# echo "$LIST"

set nonomatch

cd $WORKFLOW_DATA

while (-e GATEKEEPERBUSY)
    echo -n '.'
    sleep 1
end

clear

echo " "
set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`"_UTC" 
echo -n "TIME = $nowtxt, LAST_NEWICKET = "
cat LAST_NEWTICKET

cd $WORKFLOW_DATA/gates
foreach gate ( $LIST )
    cd $WORKFLOW_DATA/gates/$gate
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
        cat ../product

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
