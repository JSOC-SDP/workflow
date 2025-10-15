#! /bin/csh -f

# status for DSDS 6-hour datasets.
# keyword is DSDS index value, not a time.
# but low and high are stored as time.

# echo starting $0 $*
# set echo

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

if ( ! $?WORKFLOW_DIR ) then
    echo WORKFLOW_DIR environment variable is undefined, setting local variable to "${DRMS_SRC_INSTALL_DIR}"/workflow
    set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow
endif

set SHOW_COVERAGE = "${DRMS_BINS_INSTALL_DIR}"/show_coverage
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

# Ugh
set TIME_INDEX = time_index

cd $WORKFLOW_DATA/gates
set gate = $1
cd $gate
# ignore already in the gate dir

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
if ($low == "NaN") then
    set nancount = 1
    set low = `$SHOW_INFO -q  $product'[^]' key=$key`
    if ($?) then
      echo $0 $* FAILED
      exit 1
    endif
    $TIME_INDEX six=$low -t > low
else
    set low = `$TIME_INDEX -6 time=$low`
endif

if ($high == "NaN") @ nancount = $nancount + 1

set high = `$SHOW_INFO -q  $product'[$]' key=$key`
if ($?) then
   echo $0 $* FAILED
   exit 1
endif
$TIME_INDEX six=$high -t > high

# now low and high are hour numbers and file low and file high are matching times.

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
  set low = `$TIME_INDEX time=$low -6`
  set high = `$TIME_INDEX time=$high -6`
  if ($nancount == 2) then
    $SHOW_COVERAGE ds=$product low=$minlow high=$maxhigh -iq > coverage
  else
    $SHOW_COVERAGE ds=$product low=$low high=$high -iq 
  endif

endif

set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
echo $nowtxt > lastupdate

rm -f statusbusy
