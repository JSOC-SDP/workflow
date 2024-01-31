#! /bin/csh -f
# set echo

# echo starting $0 $*
if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set SHOW_COVERAGE = "${DRMS_BINS_INSTALL_DIR}"/show_coverage
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info

cd $WORKFLOW_DATA/gates
set gate = $1
cd $gate

set product = `cat product`
set key = `cat key`
set low = `cat low`
set high = `cat high`
set keytype = `cat type`
set nancount = 0

# set echo

if ($low == "NaN") then
    set nancount = 1
    if (`$SHOW_INFO -iq $product n=1 | wc -l` <= 0) then
        echo $0 $* status of $product Empty Series
        echo "-1" > low
        echo "-1" > high
        set STATUS = 0
        goto EXITPLACE
    endif
    if ($keytype == time) then
#    $SHOW_INFO -q $product'[? $key > 0 ?]' n=1' key=$key > low
      $SHOW_INFO -q  $product'[? '$key' > 0 ?]' n=1 key=$key | tail -1 > low
      if ($?) then
         echo $0 $* FAILED
         set STATUS = 1
         goto EXITPLACE
      endif
    else
      $SHOW_INFO -q  $product'[^]' key=$key | tail -1 > low
      if ($?) then
         echo $0 $* FAILED
         set STATUS = 1
         goto EXITPLACE
      endif
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

$SHOW_INFO -q  $product'[$]' key=$key | tail -1 > high
if ($?) then
   echo $0 $* FAILED
   set STATUS = 1
   goto EXITPLACE
endif

# if ($#argv < 2) then
#   set nhigh = `wc -c <high`
#  if ($nhigh == 0) then # There are no records in the series
#   echo #### SETTING -1 where product=$product and show_info call gives:
#   $SHOW_INFO -q  $product'[$]' key=$key 
#         echo "-1" > low
#         echo "-1" > high
#         set STATUS = 0
#         goto EXITPLACE
#   endif
# endif

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
