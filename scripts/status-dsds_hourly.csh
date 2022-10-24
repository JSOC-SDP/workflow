#! /bin/csh -f

# status for DSDS 1-hour datasets.

# echo starting $0 $*
# set echo

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

# ignore fact that are already in the gate dir
cd $WFDIR/gates
set gate = $1
cd $gate

# load gate keywords
set product = `cat product`
set key = `cat key`
set low = `cat low`
set low_t = `time_convert time=$low`
set low = `time_convert zone=TAI s=$low_t`
set high = `cat high`
set high_t = `time_convert time=$high`
set high = `time_convert zone=TAI s=$high_t`

set nancount = 0

# special case, used to initialize gate info
if ($low == "NaN") then
    set nancount = 1
    set low = `show_info -q  $product'[^]' key=$key`
    if ($?) then
      echo $0 $* FAILED
      exit 1
    endif
    time_index hour=$low -t > low
else
    set low = `time_index -h time=$low`
endif

if ($high == "NaN") @ nancount = $nancount + 1

set high = `show_info -q  $product'[$]' key=$key`
if ($?) then
   echo $0 $* FAILED
   exit 1
endif
time_index hour=$high -t > high

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
  set low = `time_index time=$low -h`
  set high = `time_index time=$high -h`
  if ($nancount == 2) then
    show_coverage ds=$product low=$minlow high=$maxhigh -iq > coverage
  else
    show_coverage ds=$product low=$low high=$high -iq 
  endif

endif

set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
echo $nowtxt > lastupdate

rm -f statusbusy
