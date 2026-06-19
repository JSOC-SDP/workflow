#! /bin/csh -f

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

@ YEAR = `date +%Y`
set bad = 0

foreach ticket ( $WORKFLOW_DATA/tasks/*/active/*$YEAR*/ticket )
    @ lines = `wc -l $ticket | awk '{print $1}'`
    if ( $lines < 5 ) then
        echo ""
        echo "*** BAD TICKET(S) ***"
        ls $ticket 
        set bad = 1
    endif

end

foreach low ( `ls -1 $WORKFLOW_DATA/gates/*/low | grep -v lev0 | grep -v Synop | grep -v Limb | grep -v harpImages` )
    @ lines = `wc -l $low | awk '{print $1}'`
    if ( $lines < 1 ) then
        echo ""
        echo "*** BAD LOW FILE(S) ***"
        ls $low
        set bad = 1
    endif

    set Ltime = `cat $low`
    @ Ltime_s = `$TIME_CONVERT time=$Ltime`
    if ( $Ltime_s < 0 ) then
        echo ""
        echo "*** BAD LOW FILE(S) ***"
        ls $low
        set bad = 1
    endif
end

foreach high ( `ls -1 $WORKFLOW_DATA/gates/*/high | grep -v lev0 | grep -v Synop | grep -v Limb | grep -v harpImages` )
    @ lines = `wc -l $high | awk '{print $1}'`
    if ( $lines < 1 ) then
        echo ""
        echo "*** BAD HIGH FILE(S) ***"
        ls $high
        set bad = 1
    endif

    set Htime = `cat $high`
    @ Htime_s = `$TIME_CONVERT time=$Htime`
    if ( $Htime_s < 0 ) then
        echo ""
        echo "*** BAD HIGH FILE(S) ***"
        ls $high
        set bad = 1
    endif
end

foreach next ( $WORKFLOW_DATA/gates/*/nextupdate )
    @ lines = `wc -l $next | awk '{print $1}'`
    if ( $lines < 1 ) then
        echo""
        echo "*** BAD NEXTUPDATE FILE(S) ***"
        ls $next
        set bad = 1
    endif

    set nextt = `cat $next`
    @ nextt_s = `$TIME_CONVERT time=$nextt`
    if ( $nextt_s < 0 ) then
        echo ""
        echo "*** BAD NEXTUPDATE FILE(S) ***"
        ls $next
        set bad = 1
    endif
end

if ( $bad == 0 ) then
    echo ""
    echo "All tickets, low, high, and nextupdate files are OK."
    echo ""
endif
