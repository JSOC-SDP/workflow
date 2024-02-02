#! /bin/csh -f
# the clock status task simply reflects the current time
if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

cd $WORKFLOW_DATA/gates/$1
set NOW = `date -u +%Y.%m.%d_%H:%M:%S`
echo $NOW > high
echo $NOW > lastupdate
rm -f statusbusy
