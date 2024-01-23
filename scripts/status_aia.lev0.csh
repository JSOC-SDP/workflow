#! /bin/csh -f
# set echo

# this status task is designed for aia.lev0 and hmi.lev0 only

# echo starting $0 $*

if ($?WORKFLOW_DATA) then
  set WFDIR = $WORKFLOW_DATA
else
  echo Need WORKFLOW_DATA variable to be set.
  exit 1
endif

set SHOW_COVERAGE = "${DRMS_BINS_INSTALL_DIR}"/show_coverage
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info

cd $WFDIR/gates
set gate = $1
cd $gate

set product = `cat product`
set key = `cat key`
set low = `cat low`
set high = `cat high`
set nancount = 0

# set echo

if ($low == "NaN") then
    set nancount = 1
    # 0X1C000000 == 469762048
    if (`$SHOW_INFO -cq $product'[? FSN < 469762048 ?]'` <= 0) then
        echo $0 $* status of $product Empty Series
        echo "-1" > low
        echo "-1" > high
        set STATUS = 0
        goto EXITPLACE
    endif
    $SHOW_INFO -q  $product'[^]' key=$key > low
    if ($?) then
       echo $0 $* FAILED
       set STATUS = 1
       goto EXITPLACE
    endif
    set nlow = `wc -c <low`
    if ($nlow == 0) then # There are no records in the series
        echo "-1" > low
        echo "-1" > high
        set STATUS = 0
        goto EXITPLACE
    endif
endif
set low = `cat low`

if ($high == "NaN") @ nancount = $nancount + 1

$SHOW_INFO -q  $product'[? FSN < 469762048 ?]' n=-1 key=$key > high
if ($?) then
   echo $0 $* FAILED
   set STATUS = 1
   goto EXITPLACE
endif

set high = `cat high`

# unset echo

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
  if ($nancount == 2) then
    $SHOW_COVERAGE ds=$product low=$minlow high=$maxhigh -iq $miscargs > coverage
  else
    $SHOW_COVERAGE ds=$product low=$low high=$high -iq $miscargs
  endif

endif

set STATUS = 0
EXITPLACE:
set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
echo $nowtxt > lastupdate

rm -f statusbusy
exit $STATUS
