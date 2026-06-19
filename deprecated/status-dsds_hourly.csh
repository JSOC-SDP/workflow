#! /bin/csh -f

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

# status for DSDS 1-hour datasets.

# echo starting $0 $*
# set echo

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

set SHOW_COVERAGE = "${DRMS_BINS_INSTALL_DIR}"/show_coverage
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

# Ugh
set TIME_INDEX = time_index

# ignore fact that are already in the gate dir
cd $WORKFLOW_DATA/gates
set gate = $1
cd $gate

# load gate keywords
set product = `cat product`
set key = `cat key`
set low = `cat low`
set low_t = `$TIME_CONVERT time=$low`
set low = `$TIME_CONVERT zone=TAI s=$low_t`
set high = `cat high`
set high_t = `$TIME_CONVERT time=$high`
set high = `$TIME_CONVERT zone=TAI s=$high_t`

set nancount = 0

# UGH
# time_index not in DRMS
# special case, used to initialize gate info
if ($low == "NaN") then
    set nancount = 1
    set low = `$SHOW_INFO -q  $product'[^]' key=$key`
    if ($?) then
      echo $0 $* FAILED
      exit 1
    endif
    $TIME_INDEX hour=$low -t > low
else
    set low = `$TIME_INDEX -h time=$low`
endif

if ($high == "NaN") @ nancount = $nancount + 1

set high = `$SHOW_INFO -q  $product'[$]' key=$key`
if ($?) then
   echo $0 $* FAILED
   exit 1
endif
$TIME_INDEX hour=$high -t > high

# now variables low and high are hour numbers and file low and file high are matching times.

if ($#argv > 1) then # get coverage map
  set minlow = $low
  set maxhigh = $high
  set miscargs
  shift
  while ($#argv > 0)
    if ($1 =~ "low=*") then
      set $1
    else if ($1 =~ "high=*") then
      set $1
    else
      set miscargs = "$miscargs $1"
    endif
    shift
  end
  set low = `$TIME_INDEX time=$low -h`
  set high = `$TIME_INDEX time=$high -h`
  if ($nancount == 2) then
    $SHOW_COVERAGE ds=$product low=$minlow high=$maxhigh -iq > coverage
  else
    $SHOW_COVERAGE ds=$product low=$low high=$high -iq 
  endif

endif

set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
echo $nowtxt > lastupdate

rm -f statusbusy
