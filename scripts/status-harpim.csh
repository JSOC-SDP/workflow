#! /bin/csh -f
# set echo

# echo starting $0 $*

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info

cd $WORKFLOW_DATA/gates
set gate = $1
cd $gate

set product = hmi.harp_images
set key = DAY
set low = `cat low`
set high = `cat high`
set keytype = `cat type`

set low = `cat low`

$SHOW_INFO -q  $product'[$]' key=$key | tail -1 > high
if ($?) then
   echo $0 $* FAILED
   set STATUS = 1
   goto EXITPLACE
endif

set high = `cat high`

set STATUS = 0
EXITPLACE:
set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
echo $nowtxt > lastupdate

rm -f statusbusy
exit $STATUS
