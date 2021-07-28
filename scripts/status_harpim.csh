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

set low = 2010.05.01
set high = 2010.02.02

set echo
cd /web/jsoc/htdocs/doc/data/hmi/harp/harp_definitive
set last_year = `ls -1d 20* | tail -1 | cut -c1-4`
cd $last_year
set last_month = `ls -1 | tail -1 | cut -c1-2`
cd $last_month
set last_day = `ls -1 | tail -1 | cut -c1-2`
set imgDir = /web/jsoc/htdocs/doc/data/hmi/harp/harp_definitive/$last_year/$last_month/$last_day

set gate = hmi_harpimages
cd $WFDIR/gates/$gate

set high = `ls -1H $imgDir | grep png | tail -1 | awk -F\. '{print $2"."$3"."$4}'`

echo $low > low
echo $high > high

# Update the lastupdate state-file content.
set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
echo "$nowtxt" > lastupdate
@ now_s = `/home/jsoc/cvs/Development/JSOC/bin/linux_avx/time_convert time=$nowtxt`
@ next_s = $now_s + `cat updatedelta`
set next = `/home/jsoc/cvs/Development/JSOC/bin/linux_avx/time_convert s=$next_s zone=UTC`
echo "$next" > nextupdata

rm -f statusbusy
exit 0
