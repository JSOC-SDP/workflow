#! /bin/csh -f
# the clock status task simply reflects the current time

set WFDIR = /home/jsoc/pipeline/

cd /home/jsoc/pipeline//gates/$1
set NOW = `date -u +%Y.%m.%d_%H:%M:%S`
echo $NOW > high
echo $NOW > lastupdate
rm -f statusbusy
