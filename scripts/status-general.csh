#! /bin/csh -f
# set echo

# echo starting $0 $*

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

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
    if (`show_info -cq $product` <= 0) then
        echo $0 $* status of $product Empty Series
        echo "-1" > low
        echo "-1" > high
        set STATUS = 0
        goto EXITPLACE
    endif
    show_info -q  $product'[^]' key=$key > low
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

show_info -q  $product'[$]' key=$key > high
if ($?) then
   echo $0 $* FAILED
   set STATUS = 1
   goto EXITPLACE
endif
set nhigh = `wc -c <high`
if ($nhigh == 0) then # There are no records in the series
echo #### SETTING -1 where product=$product and show_info call gives:
show_info -q  $product'[$]' key=$key 
        echo "-1" > low
        echo "-1" > high
        set STATUS = 0
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
    show_coverage ds=$product low=$minlow high=$maxhigh -iq $miscargs > coverage
  else
    show_coverage ds=$product low=$low high=$high -iq $miscargs
  endif

endif

set STATUS = 0
EXITPLACE:
set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
echo $nowtxt > lastupdate

rm -f statusbusy
exit $STATUS
