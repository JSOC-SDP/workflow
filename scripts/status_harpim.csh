#! /bin/csh -f

# I think the point of this script is to write out the low, high, and lastupdate gate state files.
# The general status script also writes out the coverage file, but I do not know what that file
# is for - skipping for now.

if ($?WORKFLOW_ROOT) then
    set WFDIR = $WORKFLOW_DATA
    set WFCODE = $WORKFLOW_ROOT
else
    echo Need WORKFLOW_ROOT variable to be set.
    exit 1
endif

set imgDir = /web/jsoc/htdocs/doc/data/hmi/harp/harp_definitive

set gate = hmi_harpimages
cd $WFDIR/gates/$gate

set low = `ls -1 $imgDir | grep png | head -1 | awk -F\. '{print $2"."$3"."$4}'`
set high = `ls -1 $imgDir | grep png | tail -1 | awk -F\. '{print $2"."$3"."$4}'`

echo $low > low
echo $high > high

# Update the lastupdate state-file content.
set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
echo $nowtxt > lastupdate

rm -f statusbusy
exit 0
