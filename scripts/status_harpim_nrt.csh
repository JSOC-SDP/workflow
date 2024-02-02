#! /bin/csh -f

# I think the point of this script is to write out the low, high, and lastupdate gate state files.
# The general status script also writes out the coverage file, but I do not know what that file
# is for - skipping for now.

set HARPSERIES = hmi.Mharp_720_nrt

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info

set gate = $1
cd $WORKFLOW_DATA/gates/$gate

# Check for an empty series, then update the low and high state-file contents.
if (`$SHOW_INFO -iq $HARPSERIES n=1 | wc -l` <= 0) then
    echo $0 $* $HARPSERIES is an empty series
    echo "-1" > low
    echo "-1" > high
else
    $SHOW_INFO -q  $HARPSERIES'[][^]' key=T_REC | tail -1 > low
    if ($?) then
        echo Could not obtain $HARPSERIES time of first observation
        exit 1
    else
        $SHOW_INFO -q  $HARPSERIES'[][$]' key=T_REC | tail -1 > high
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
