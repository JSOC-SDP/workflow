#! /bin/csh -f

# I think the point of this script is to write out the low, high, and lastupdate gate state files.
# The general status script also writes out the coverage file, but I do not know what that file
# is for - skipping for now.

set HARPSERIES = hmi.Mharp_720_nrt

if ($?WORKFLOW_ROOT) then
    set WFDIR = $WORKFLOW_DATA
    set WFCODE = $WORKFLOW_ROOT
else
    echo Need WORKFLOW_ROOT variable to be set.
    exit 1
endif

set gate = $1
cd $WFDIR/gates/$gate

# Check for an empty series, then update the low and high state-file contents.
if (`show_info -iq $HARPSERIES n=1 | wc -l` <= 0) then
    echo $0 $* $HARPSERIES is an empty series
    echo "-1" > low
    echo "-1" > high
else
    show_info -q  $HARPSERIES'[][^]' key=T_REC | tail -1 > low
    if ($?) then
        echo Could not obtain $HARPSERIES time of first observation
        exit 1
    else
        show_info -q  $HARPSERIES'[][$]' key=T_REC | tail -1 > high
        if ($?) then
            echo Could not obtain $HARPSERIES time of last observation
            exit 1
        endif
    endif
endif

# Update the lastupdate state-file content.
set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
echo $nowtxt > lastupdate

rm -f statusbusy
exit 0
